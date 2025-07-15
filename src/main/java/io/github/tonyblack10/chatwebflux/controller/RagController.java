package io.github.tonyblack10.chatwebflux.controller;

import io.github.tonyblack10.chatwebflux.service.RagService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.multipart.FilePart;
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

  public RagController(RagService ragService) {
    this.ragService = ragService;
  }

  @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @ResponseBody
  public Mono<ResponseEntity<String>> uploadDocuments(@RequestPart("files") Flux<FilePart> files) {
    return ragService.processDocuments(files)
        .then(Mono.just(ResponseEntity.ok("Documentos processados e armazenados no vector store com sucesso!")))
        .onErrorResume(IllegalArgumentException.class,
            error -> Mono.just(ResponseEntity.badRequest().body(error.getMessage())))
        .onErrorResume(Exception.class,
            error -> Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Erro interno: " + error.getMessage())));
  }
}
