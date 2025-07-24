package io.github.tonyblack10.chatwebflux.controller;

import gg.jte.TemplateEngine;
import gg.jte.output.StringOutput;
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

    private final TemplateEngine templateEngine;

    @Autowired
    public PageController(TemplateEngine templateEngine) {
        this.templateEngine = templateEngine;
    }

    @GetMapping(value = "/chat", produces = MediaType.TEXT_HTML_VALUE)
    public Mono<String> chat() {
        Map<String, Object> model = new HashMap<>();
        model.put("message", "Hello from HTMX! This content was loaded dynamically.");
        model.put("timestamp", System.currentTimeMillis());

        StringOutput output = new StringOutput();
        templateEngine.render("chat.jte", model, output);

        return Mono.just(output.toString());
    }

    @GetMapping(value = "/upload-documents", produces = MediaType.TEXT_HTML_VALUE)
    public Mono<String> uploadDocuments() {
        Map<String, Object> model = new HashMap<>();
        model.put("message", "Hello from HTMX! This content was loaded dynamically.");
        model.put("timestamp", System.currentTimeMillis());

        StringOutput output = new StringOutput();
        templateEngine.render("upload_documents.jte", model, output);

        return Mono.just(output.toString());
    }
}
