package io.github.tonyblack10.chatwebflux.controller;

import io.github.tonyblack10.chatwebflux.service.RagService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseBody;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.util.Set;

@Controller
@RequestMapping("/rag")
public class RagController {

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

  private final RagService ragService;

  public RagController(RagService ragService) {
    this.ragService = ragService;
  }

  @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @ResponseBody
  public Mono<ResponseEntity<String>> uploadDocuments(@RequestPart("files") Flux<FilePart> files) {
    return files
        .collectList()
        .flatMap(this::validateFiles)
        .flatMapMany(Flux::fromIterable)
        .flatMap(this::convertToMessage)
        .transform(this::processDocuments)
        .then(Mono.just(ResponseEntity.ok("Documentos processados e armazenados no vector store com sucesso!")))
        .onErrorResume(IllegalArgumentException.class,
            error -> Mono.just(ResponseEntity.badRequest().body(error.getMessage())))
        .onErrorResume(Exception.class,
            error -> Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Erro interno: " + error.getMessage())));
  }

  private Mono<java.util.List<FilePart>> validateFiles(java.util.List<FilePart> fileParts) {
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

  private Mono<Message<byte[]>> convertToMessage(FilePart filePart) {
    return filePart.content()
        .map(dataBuffer -> {
          byte[] bytes = new byte[dataBuffer.readableByteCount()];
          dataBuffer.read(bytes);
          // DataBuffer não precisa de release manual no WebFlux
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

  private Mono<Void> processDocuments(Flux<Message<byte[]>> messageFlux) {
    // Composição funcional usando os métodos do RagService
    return messageFlux
        .transform(ragService.documentReader())      // Converte bytes em documentos
        .transform(ragService.splitter())            // Divide documentos em chunks
        .flatMap(documents -> {
          // Armazenar no vector store
          ragService.getVectorStore().accept(documents);
          return Mono.just(documents);
        })
        .then();
  }
}
