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
    LOGGER.info("🚀 Iniciando processamento completo de documentos");

    return files
        .collectList()
        .doOnNext(fileParts -> LOGGER.info("📂 Recebidos {} arquivos para processamento: {}",
            fileParts.size(),
            fileParts.stream().map(FilePart::filename).toList()))
        .flatMap(this::validateFiles)
        .doOnNext(validatedFiles -> LOGGER.info("✅ Validação concluída com sucesso para {} arquivos", validatedFiles.size()))
        .flatMapMany(Flux::fromIterable)
        .flatMap(this::convertToMessage)
        .doOnNext(message -> LOGGER.info("🔄 Arquivo '{}' convertido para mensagem ({} bytes)",
            message.getHeaders().get("file_name"),
            message.getPayload().length))
        .flatMap(this::readDocument)
        .doOnNext(documents -> {
            String source = (String) documents.getFirst().getMetadata().get("source");
            int totalChars = documents.stream()
                .filter(doc -> doc.getText() != null)
                .mapToInt(doc -> doc.getText().length())
                .sum();
            LOGGER.info("📖 Extração de texto concluída para '{}': {} documentos, {} caracteres totais",
                source, documents.size(), totalChars);
        })
        .flatMap(this::splitDocuments)
        .doOnNext(splitDocs -> {
            String source = (String) splitDocs.getFirst().getMetadata().get("source");
            LOGGER.info("✂️ Divisão em chunks concluída para '{}': {} chunks gerados", source, splitDocs.size());
        })
        .doOnComplete(() -> LOGGER.info("🎉 Processamento de documentos concluído com sucesso"))
        .doOnError(error -> LOGGER.error("❌ Erro durante o processamento de documentos: {}", error.getMessage(), error));
  }

  public Mono<List<FilePart>> validateFiles(List<FilePart> fileParts) {
    LOGGER.info("🔍 Iniciando validação de {} arquivos", fileParts.size());

    if (fileParts.isEmpty()) {
      LOGGER.error("❌ Nenhum arquivo foi enviado para validação");
      return Mono.error(new IllegalArgumentException("Nenhum arquivo foi enviado"));
    }

    // Validar tipos de arquivo
    for (FilePart filePart : fileParts) {
      MediaType contentType = filePart.headers().getContentType();
      String contentTypeStr = contentType != null
          ? contentType.toString()
          : "application/octet-stream";

      LOGGER.debug("🔎 Validando arquivo '{}' - tipo: {}", filePart.filename(), contentTypeStr);

      if (!SUPPORTED_CONTENT_TYPES.contains(contentTypeStr)) {
        LOGGER.error("🚫 Tipo de arquivo não suportado: {} para o arquivo: {}", contentTypeStr, filePart.filename());
        return Mono.error(new IllegalArgumentException(
            "Tipo de arquivo não suportado: " + contentTypeStr + " para o arquivo: "
                + filePart.filename()));
      }
    }

    LOGGER.info("✅ Tipos de arquivo validados com sucesso");

    // Calcular tamanho total dos arquivos
    return Flux.fromIterable(fileParts)
        .flatMap(filePart ->
            filePart.content()
                .map(dataBuffer -> (long) dataBuffer.readableByteCount())
                .reduce(0L, Long::sum)
                .doOnNext(size -> LOGGER.debug("📏 Tamanho do arquivo '{}': {} KB",
                    filePart.filename(), size / 1024))
        )
        .reduce(0L, Long::sum)
        .doOnNext(totalSize -> LOGGER.info("📊 Tamanho total dos arquivos: {} MB",
            String.format("%.2f", (double) totalSize / (1024 * 1024))))
        .flatMap(totalSize -> {
          if (totalSize > MAX_TOTAL_SIZE) {
            LOGGER.error("🚫 Tamanho total dos arquivos ({} MB) excede o limite de 20MB",
                String.format("%.2f", (double) totalSize / (1024 * 1024)));
            return Mono.error(new IllegalArgumentException(
                "Tamanho total dos arquivos excede o limite de 20MB. Tamanho atual: " +
                    (totalSize / 1024 / 1024) + "MB"));
          }
          LOGGER.info("✅ Validação de tamanho concluída - dentro do limite permitido");
          return Mono.just(fileParts);
        });
  }

  public Mono<Message<byte[]>> convertToMessage(FilePart filePart) {
    String filename = filePart.filename();
    LOGGER.debug("🔄 Convertendo arquivo '{}' para Message", filename);

    return filePart.content()
        .map(dataBuffer -> {
          byte[] bytes = new byte[dataBuffer.readableByteCount()];
          dataBuffer.read(bytes);
          return bytes;
        })
        .reduce(new byte[0], this::combineByteArrays)
        .map(bytes -> {
          LOGGER.debug("📦 Arquivo '{}' convertido - {} bytes processados", filename, bytes.length);
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

    LOGGER.info("📖 Extraindo texto do arquivo '{}' ({} KB) usando Tika Document Reader",
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
            LOGGER.debug("📄 Documento extraído: {} caracteres", charCount);
          })
          .toList();

      long endTime = System.currentTimeMillis();
      int totalChars = documents.stream()
          .filter(doc -> doc.getText() != null)
          .mapToInt(doc -> doc.getText().length())
          .sum();

      LOGGER.info("✅ Extração Tika concluída para '{}' em {}ms - {} documentos, {} caracteres",
          filename, (endTime - startTime), documents.size(), totalChars);

      return documents;
    }).subscribeOn(Schedulers.boundedElastic());
  }

  public Mono<List<Document>> splitDocuments(List<Document> documents) {
    String sourceFile = documents.isEmpty() ? "unknown" :
        (String) documents.getFirst().getMetadata().get("source");

    LOGGER.info("✂️ Dividindo {} documentos de '{}' em chunks menores", documents.size(), sourceFile);

    return Mono.fromCallable(() -> {
      long startTime = System.currentTimeMillis();

      List<Document> splitDocuments = new TokenTextSplitter().apply(documents);

      long endTime = System.currentTimeMillis();

      LOGGER.info("✅ Divisão concluída para '{}' em {}ms - {} chunks gerados",
          sourceFile, (endTime - startTime), splitDocuments.size());

      // Log estatísticas dos chunks
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

        LOGGER.info("📊 Estatísticas dos chunks de '{}': min={} chars, max={} chars, média={} chars",
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
