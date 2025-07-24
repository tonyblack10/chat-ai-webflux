package io.github.tonyblack10.chatwebflux.controller;

import gg.jte.TemplateEngine;
import gg.jte.output.StringOutput;
import java.util.HashMap;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
public class ChatAiController {

  private final TemplateEngine templateEngine;

  public ChatAiController(TemplateEngine templateEngine) {
    this.templateEngine = templateEngine;
  }

  @PostMapping(value = "/chat/send", produces = MediaType.TEXT_HTML_VALUE)
  public Mono<String> chat(String message) {
    Map<String, Object> model = new HashMap<>();
    model.put("response", "<p>Quais são as melhores práticas para desenvolvimento web com Spring Boot e WebFlux?</p>");

    StringOutput output = new StringOutput();
    templateEngine.render("fragments/user_message.jte", model, output);

    return Mono.just(output.toString());
  }

}
