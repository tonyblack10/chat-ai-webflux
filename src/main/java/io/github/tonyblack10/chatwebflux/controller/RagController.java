package io.github.tonyblack10.chatwebflux.controller;

import io.github.tonyblack10.chatwebflux.service.RagService;
import java.util.Map;
import java.util.HashMap;
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

  @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
  @ResponseBody
  public Mono<ResponseEntity<Map<String, Object>>> uploadDocuments(@RequestPart("files") Flux<FilePart> files) {
    return ragService.processDocuments(files)
        .collectList()
        .map(processedFiles -> {
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Documentos processados e armazenados no vector store com sucesso!");
            response.put("files", processedFiles);
            return ResponseEntity.ok(response);
        })
        .onErrorResume(IllegalArgumentException.class, error -> {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", error.getMessage());
            return Mono.just(ResponseEntity.badRequest().body(response));
        })
        .onErrorResume(Exception.class, error -> {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Erro interno: " + error.getMessage());
            return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response));
        });
  }
}
