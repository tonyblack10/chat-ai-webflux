package io.github.tonyblack10.chatwebflux.controller;

import io.github.tonyblack10.chatwebflux.util.TemplateRenderer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/page")
public class PageController {

    private final TemplateRenderer templateRenderer;

    @Autowired
    public PageController(TemplateRenderer templateRenderer) {
        this.templateRenderer = templateRenderer;
    }

    @GetMapping(value = "/chat", produces = MediaType.TEXT_HTML_VALUE)
    public Mono<String> chat() {
        Map<String, Object> model = new HashMap<>();
        model.put("message", "Hello from HTMX! This content was loaded dynamically.");
        model.put("timestamp", System.currentTimeMillis());

        return templateRenderer.render("pages/chat_ai.jte", model);
    }

    @GetMapping(value = "/upload-documents", produces = MediaType.TEXT_HTML_VALUE)
    public Mono<String> uploadDocuments() {
        Map<String, Object> model = new HashMap<>();
        model.put("message", "Hello from HTMX! This content was loaded dynamically.");
        model.put("timestamp", System.currentTimeMillis());

        return templateRenderer.render("upload_documents.jte", model);
    }
}
