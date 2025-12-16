package io.github.tonyblack10.chatwebflux.controller;

import io.github.tonyblack10.chatwebflux.service.RagService;
import io.github.tonyblack10.chatwebflux.util.ResponseBuilder;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
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
            Map<String, Object> response = ResponseBuilder.success(
                "Documentos processados e armazenados no vector store com sucesso!",
                "files",
                processedFiles
            );
            return ResponseEntity.ok(response);
        })
        .onErrorResume(IllegalArgumentException.class, error -> {
            Map<String, Object> response = ResponseBuilder.error(error.getMessage());
            return Mono.just(ResponseEntity.badRequest().body(response));
        })
        .onErrorResume(Exception.class, error -> {
            Map<String, Object> response = ResponseBuilder.error("Erro interno: " + error.getMessage());
            return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response));
        });
  }

  @GetMapping(value = "/history", produces = MediaType.APPLICATION_JSON_VALUE)
  @ResponseBody
  public Mono<ResponseEntity<Map<String, Object>>> getUploadHistory() {
    return ragService.getUploadHistory()
        .collectList()
        .map(files -> {
            Map<String, Object> response = ResponseBuilder.successWithData("files", files);
            return ResponseEntity.ok(response);
        })
        .onErrorResume(Exception.class, error -> {
            Map<String, Object> response = ResponseBuilder.error("Erro ao buscar histórico: " + error.getMessage());
            return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response));
        });
  }

  @DeleteMapping(value = "/document/{fileName}", produces = MediaType.APPLICATION_JSON_VALUE)
  @ResponseBody
  public Mono<ResponseEntity<Map<String, Object>>> deleteDocument(@PathVariable String fileName) {
    return ragService.deleteDocument(fileName)
        .map(deleted -> {
            Map<String, Object> response = ResponseBuilder.conditional(
                deleted,
                "Documento removido com sucesso",
                "Documento não encontrado"
            );
            return ResponseEntity.ok(response);
        })
        .onErrorResume(Exception.class, error -> {
            Map<String, Object> response = ResponseBuilder.error("Erro ao excluir documento: " + error.getMessage());
            return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response));
        });
  }
}
