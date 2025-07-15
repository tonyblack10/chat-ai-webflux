package io.github.tonyblack10.chatwebflux.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.document.Document;
import org.springframework.ai.reader.tika.TikaDocumentReader;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.util.List;
import java.util.Set;

@Component
public class DocumentProcessorUtil {

  private static final Logger LOGGER = LoggerFactory.getLogger(DocumentProcessorUtil.class);
  private static final long MAX_TOTAL_SIZE = 20 * 1024 * 1024; // 20MB in bytes

  // Formatos suportados pelo Tika Document Reader
  private static final Set<String> SUPPORTED_CONTENT_TYPES = Set.of(
      "application/pdf",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.ms-powerpoint",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "text/plain",
      "text/html",
      "text/xml",
      "application/rtf",
      "application/vnd.oasis.opendocument.text",
      "application/vnd.oasis.opendocument.spreadsheet",
      "application/vnd.oasis.opendocument.presentation"
  );

  public Flux<List<Document>> processDocuments(Flux<FilePart> files) {
    LOGGER.info("🚀 Starting complete document processing");

    return files
        .collectList()
        .doOnNext(fileParts -> LOGGER.info("📂 Received {} files for processing: {}",
            fileParts.size(),
            fileParts.stream().map(FilePart::filename).toList()))
        .flatMap(this::validateFiles)
        .doOnNext(validatedFiles -> LOGGER.info("✅ Validation completed successfully for {} files",
            validatedFiles.size()))
        .flatMapMany(Flux::fromIterable)
        .flatMap(this::convertToMessage)
        .doOnNext(message -> LOGGER.info("🔄 File '{}' converted to message ({} bytes)",
            message.getHeaders().get("file_name"),
            message.getPayload().length))
        .flatMap(this::readDocument)
        .doOnNext(documents -> {
          String source = (String) documents.getFirst().getMetadata().get("source");
          int totalChars = documents.stream()
              .filter(doc -> doc.getText() != null)
              .mapToInt(doc -> doc.getText().length())
              .sum();
          LOGGER.info("📖 Text extraction completed for '{}': {} documents, {} total characters",
              source, documents.size(), totalChars);
        })
        .flatMap(this::splitDocuments)
        .doOnNext(splitDocs -> {
          String source = (String) splitDocs.getFirst().getMetadata().get("source");
          LOGGER.info("✂️ Chunk splitting completed for '{}': {} chunks generated", source,
              splitDocs.size());
        })
        .doOnComplete(() -> LOGGER.info("🎉 Document processing completed successfully"))
        .doOnError(
            error -> LOGGER.error("❌ Error during document processing: {}", error.getMessage(),
                error));
  }

  public Mono<List<FilePart>> validateFiles(List<FilePart> fileParts) {
    LOGGER.info("🔍 Starting validation of {} files", fileParts.size());

    if (fileParts.isEmpty()) {
      LOGGER.error("❌ No files were sent for validation");
      return Mono.error(new IllegalArgumentException("No files were sent"));
    }

    // Validar tipos de arquivo
    for (FilePart filePart : fileParts) {
      MediaType contentType = filePart.headers().getContentType();
      String contentTypeStr = contentType != null
          ? contentType.toString()
          : "application/octet-stream";

      LOGGER.debug("🔎 Validating file '{}' - type: {}", filePart.filename(), contentTypeStr);

      if (!SUPPORTED_CONTENT_TYPES.contains(contentTypeStr)) {
        LOGGER.error("🚫 Unsupported file type: {} for file: {}", contentTypeStr,
            filePart.filename());
        return Mono.error(new IllegalArgumentException(
            "Unsupported file type: " + contentTypeStr + " for file: "
                + filePart.filename()));
      }
    }

    LOGGER.info("✅ File types validated successfully");

    // Calcular tamanho total dos arquivos
    return Flux.fromIterable(fileParts)
        .flatMap(filePart ->
            filePart.content()
                .map(dataBuffer -> (long) dataBuffer.readableByteCount())
                .reduce(0L, Long::sum)
                .doOnNext(size -> LOGGER.debug("📏 File '{}' size: {} KB",
                    filePart.filename(), size / 1024))
        )
        .reduce(0L, Long::sum)
        .doOnNext(totalSize -> LOGGER.info("📊 Total file size: {} MB",
            String.format("%.2f", (double) totalSize / (1024 * 1024))))
        .flatMap(totalSize -> {
          if (totalSize > MAX_TOTAL_SIZE) {
            LOGGER.error("🚫 Total file size ({} MB) exceeds 20MB limit",
                String.format("%.2f", (double) totalSize / (1024 * 1024)));
            return Mono.error(new IllegalArgumentException(
                "Total file size exceeds 20MB limit. Current size: " +
                    (totalSize / 1024 / 1024) + "MB"));
          }
          LOGGER.info("✅ Size validation completed - within allowed limit");
          return Mono.just(fileParts);
        });
  }

  public Mono<Message<byte[]>> convertToMessage(FilePart filePart) {
    String filename = filePart.filename();
    LOGGER.debug("🔄 Converting file '{}' to Message", filename);

    return filePart.content()
        .map(dataBuffer -> {
          byte[] bytes = new byte[dataBuffer.readableByteCount()];
          dataBuffer.read(bytes);
          return bytes;
        })
        .reduce(new byte[0], this::combineByteArrays)
        .map(bytes -> {
          LOGGER.debug("📦 File '{}' converted - {} bytes processed", filename, bytes.length);
          return MessageBuilder.withPayload(bytes)
              .setHeader("file_name", filename)
              .setHeader("content_type", filePart.headers().getContentType())
              .build();
        })
        .subscribeOn(Schedulers.boundedElastic());
  }

  public Mono<List<Document>> readDocument(Message<byte[]> message) {
    String filename = (String) message.getHeaders().get("file_name");
    byte[] payload = message.getPayload();
    int fileSize = payload.length;

    LOGGER.info("📖 Extracting text from file '{}' ({} KB) using Tika Document Reader",
        filename, fileSize / 1024);

    return Mono.fromCallable(() -> {
      long startTime = System.currentTimeMillis();

      List<Document> documents = new TikaDocumentReader(new ByteArrayResource(payload))
          .get()
          .stream()
          .peek(document -> {
            document.getMetadata().put("source", filename);
            String text = document.getText();
            int charCount = text != null ? text.length() : 0;
            LOGGER.debug("📄 Document extracted: {} characters", charCount);
          })
          .toList();

      long endTime = System.currentTimeMillis();
      int totalChars = documents.stream()
          .filter(doc -> doc.getText() != null)
          .mapToInt(doc -> doc.getText().length())
          .sum();

      LOGGER.info("✅ Tika extraction completed for '{}' in {}ms - {} documents, {} characters",
          filename, (endTime - startTime), documents.size(), totalChars);

      return documents;
    }).subscribeOn(Schedulers.boundedElastic());
  }

  public Mono<List<Document>> splitDocuments(List<Document> documents) {
    String sourceFile = documents.isEmpty() ? "unknown" :
        (String) documents.getFirst().getMetadata().get("source");

    LOGGER.info("✂️ Splitting {} documents from '{}' into smaller chunks", documents.size(),
        sourceFile);

    return Mono.fromCallable(() -> {
      long startTime = System.currentTimeMillis();

      List<Document> splitDocuments = new TokenTextSplitter().apply(documents);

      long endTime = System.currentTimeMillis();

      LOGGER.info("✅ Splitting completed for '{}' in {}ms - {} chunks generated",
          sourceFile, (endTime - startTime), splitDocuments.size());

      // Log chunk statistics
      if (!splitDocuments.isEmpty()) {
        int minChunkSize = splitDocuments.stream()
            .filter(doc -> doc.getText() != null)
            .mapToInt(doc -> doc.getText().length())
            .min()
            .orElse(0);
        int maxChunkSize = splitDocuments.stream()
            .filter(doc -> doc.getText() != null)
            .mapToInt(doc -> doc.getText().length())
            .max()
            .orElse(0);
        double avgChunkSize = splitDocuments.stream()
            .filter(doc -> doc.getText() != null)
            .mapToInt(doc -> doc.getText().length())
            .average()
            .orElse(0);

        LOGGER.info("📊 Chunk statistics for '{}': min={} chars, max={} chars, avg={} chars",
            sourceFile, minChunkSize, maxChunkSize, String.format("%.0f", avgChunkSize));
      }

      return splitDocuments;
    }).subscribeOn(Schedulers.boundedElastic());
  }

  private byte[] combineByteArrays(byte[] array1, byte[] array2) {
    byte[] result = new byte[array1.length + array2.length];
    System.arraycopy(array1, 0, result, 0, array1.length);
    System.arraycopy(array2, 0, result, array1.length, array2.length);
    return result;
  }
}
