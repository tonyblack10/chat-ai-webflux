package io.github.tonyblack10.chatwebflux.controller;

import gg.jte.TemplateEngine;
import gg.jte.output.StringOutput;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.HashMap;
import java.util.Map;

@RestController
public class HelloController {

    private final TemplateEngine templateEngine;

    @Autowired
    public HelloController(TemplateEngine templateEngine) {
        this.templateEngine = templateEngine;
    }

    @GetMapping(value = "/hello", produces = MediaType.TEXT_HTML_VALUE)
    public Mono<String> helloHtmx() {
        Map<String, Object> model = new HashMap<>();
        model.put("message", "Hello from HTMX! This content was loaded dynamically.");
        model.put("timestamp", System.currentTimeMillis());

        StringOutput output = new StringOutput();
        // Modificado para usar diretamente o arquivo hello.jte que existe no diretório raiz de templates
        templateEngine.render("hello.jte", model, output);

        return Mono.just(output.toString());
    }
}
