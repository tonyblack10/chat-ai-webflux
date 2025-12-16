package io.github.tonyblack10.chatwebflux.util;

import gg.jte.TemplateEngine;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.util.HashMap;
import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class TemplateRendererTest {

  @Mock
  private TemplateEngine templateEngine;

  private TemplateRenderer templateRenderer;

  @BeforeEach
  void setUp() {
    MockitoAnnotations.openMocks(this);
    templateRenderer = new TemplateRenderer(templateEngine);
  }

  @Test
  void testRenderWithModel() {
    Map<String, Object> model = new HashMap<>();
    model.put("key", "value");

    doNothing().when(templateEngine).render(anyString(), any(Map.class), any());

    Mono<String> result = templateRenderer.render("test.jte", model);

    StepVerifier.create(result)
        .expectNextMatches(s -> s != null)
        .verifyComplete();

    verify(templateEngine, times(1)).render(eq("test.jte"), eq(model), any());
  }

  @Test
  void testRenderWithEmptyModel() {
    doNothing().when(templateEngine).render(anyString(), any(Map.class), any());

    Mono<String> result = templateRenderer.render("test.jte");

    StepVerifier.create(result)
        .expectNextMatches(s -> s != null)
        .verifyComplete();

    verify(templateEngine, times(1)).render(eq("test.jte"), any(Map.class), any());
  }

  @Test
  void testRenderWithSingleKeyValue() {
    doNothing().when(templateEngine).render(anyString(), any(Map.class), any());

    Mono<String> result = templateRenderer.render("test.jte", "key", "value");

    StepVerifier.create(result)
        .expectNextMatches(s -> s != null)
        .verifyComplete();

    verify(templateEngine, times(1)).render(eq("test.jte"), any(Map.class), any());
  }
}
