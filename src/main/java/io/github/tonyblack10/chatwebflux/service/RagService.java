package io.github.tonyblack10.chatwebflux.service;

import java.util.List;
import java.util.Set;
import java.util.function.Function;
import org.springframework.ai.document.Document;
import org.springframework.ai.reader.tika.TikaDocumentReader;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

@Service
public class RagService {

  private static final org.slf4j.Logger LOGGER = org.slf4j.LoggerFactory.getLogger(RagService.class);

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

  private final VectorStore vectorStore;

  public RagService(VectorStore vectorStore) {
    this.vectorStore = vectorStore;
  }

  public Mono<Void> processDocuments(Flux<FilePart> files) {
    return files
        .collectList()
        .flatMap(this::validateFiles)
        .flatMapMany(Flux::fromIterable)
        .flatMap(this::convertToMessage)
        .transform(this.documentReader())      // Converte bytes em documentos
        .transform(this.splitter())            // Divide documentos em chunks
        .flatMap(documents -> {
          // Armazenar no vector store
          this.vectorStore.accept(documents);
          return Mono.just(documents);
        })
        .then();
  }

  public Mono<List<FilePart>> validateFiles(List<FilePart> fileParts) {
    if (fileParts.isEmpty()) {
      return Mono.error(new IllegalArgumentException("Nenhum arquivo foi enviado"));
    }

    // Validar tipos de arquivo
    for (FilePart filePart : fileParts) {
      MediaType contentType = filePart.headers().getContentType();
      String contentTypeStr = contentType != null
          ? contentType.toString()
          : "application/octet-stream";

      if (!SUPPORTED_CONTENT_TYPES.contains(contentTypeStr)) {
        return Mono.error(new IllegalArgumentException(
            "Tipo de arquivo não suportado: " + contentTypeStr + " para o arquivo: " + filePart.filename()));
      }
    }

    // Calcular tamanho total dos arquivos
    return Flux.fromIterable(fileParts)
        .flatMap(filePart ->
            filePart.content()
                .map(dataBuffer -> (long) dataBuffer.readableByteCount())
                .reduce(0L, Long::sum)
        )
        .reduce(0L, Long::sum)
        .flatMap(totalSize -> {
          if (totalSize > MAX_TOTAL_SIZE) {
            return Mono.error(new IllegalArgumentException(
                "Tamanho total dos arquivos excede o limite de 20MB. Tamanho atual: " +
                (totalSize / 1024 / 1024) + "MB"));
          }
          return Mono.just(fileParts);
        });
  }

  public Mono<Message<byte[]>> convertToMessage(FilePart filePart) {
    return filePart.content()
        .map(dataBuffer -> {
          byte[] bytes = new byte[dataBuffer.readableByteCount()];
          dataBuffer.read(bytes);
          return bytes;
        })
        .reduce(new byte[0], this::combineByteArrays)
        .map(bytes -> MessageBuilder.withPayload(bytes)
            .setHeader("file_name", filePart.filename())
            .setHeader("content_type", filePart.headers().getContentType())
            .build())
        .subscribeOn(Schedulers.boundedElastic());
  }

  private byte[] combineByteArrays(byte[] array1, byte[] array2) {
    byte[] result = new byte[array1.length + array2.length];
    System.arraycopy(array1, 0, result, 0, array1.length);
    System.arraycopy(array2, 0, result, array1.length, array2.length);
    return result;
  }

  public Function<Flux<Message<byte[]>>, Flux<List<Document>>> documentReader() {
    return resourceFlux -> resourceFlux
        .map(message ->
            new TikaDocumentReader(new ByteArrayResource(message.getPayload()))
                .get()
                .stream()
                .peek(document -> {
                  document.getMetadata()
                      .put("source", message.getHeaders().get("file_name"));
                })
                .toList()
        );
  }

  public Function<Flux<List<Document>>, Flux<List<Document>>> splitter() {
    return documentListFlux ->
        documentListFlux
            .map(unsplitList -> new TokenTextSplitter().apply(unsplitList));
  }
}
