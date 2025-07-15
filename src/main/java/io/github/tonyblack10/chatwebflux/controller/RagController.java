package io.github.tonyblack10.chatwebflux.controller;

import io.github.tonyblack10.chatwebflux.service.RagService;
import io.github.tonyblack10.chatwebflux.util.DocumentProcessorUtil;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.messaging.Message;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseBody;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Controller
@RequestMapping("/rag")
public class RagController {

  private final RagService ragService;
  private final DocumentProcessorUtil documentProcessorUtil;

  public RagController(RagService ragService, DocumentProcessorUtil documentProcessorUtil) {
    this.ragService = ragService;
    this.documentProcessorUtil = documentProcessorUtil;
  }

  @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @ResponseBody
  public Mono<ResponseEntity<String>> uploadDocuments(@RequestPart("files") Flux<FilePart> files) {
    return files
        .collectList()
        .flatMap(documentProcessorUtil::validateFiles)
        .flatMapMany(Flux::fromIterable)
        .flatMap(documentProcessorUtil::convertToMessage)
        .transform(this::processDocuments)
        .then(Mono.just(ResponseEntity.ok("Documentos processados e armazenados no vector store com sucesso!")))
        .onErrorResume(IllegalArgumentException.class,
            error -> Mono.just(ResponseEntity.badRequest().body(error.getMessage())))
        .onErrorResume(Exception.class,
            error -> Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Erro interno: " + error.getMessage())));
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
