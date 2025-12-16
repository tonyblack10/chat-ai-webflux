package io.github.tonyblack10.chatwebflux.util;

import gg.jte.TemplateEngine;
import gg.jte.output.StringOutput;
import java.util.HashMap;
import java.util.Map;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

/**
 * Utility class for rendering JTE templates.
 * Helps eliminate code duplication in template rendering logic.
 */
@Component
public class TemplateRenderer {

  private final TemplateEngine templateEngine;

  public TemplateRenderer(TemplateEngine templateEngine) {
    this.templateEngine = templateEngine;
  }

  /**
   * Renders a template with the given model and returns the result as a Mono
   * @param templatePath Path to the template file
   * @param model Model data to pass to the template
   * @return Mono containing the rendered HTML string
   */
  public Mono<String> render(String templatePath, Map<String, Object> model) {
    StringOutput output = new StringOutput();
    templateEngine.render(templatePath, model, output);
    return Mono.just(output.toString());
  }

  /**
   * Renders a template with an empty model
   * @param templatePath Path to the template file
   * @return Mono containing the rendered HTML string
   */
  public Mono<String> render(String templatePath) {
    return render(templatePath, new HashMap<>());
  }

  /**
   * Renders a template with a single key-value pair in the model
   * @param templatePath Path to the template file
   * @param key Model key
   * @param value Model value
   * @return Mono containing the rendered HTML string
   */
  public Mono<String> render(String templatePath, String key, Object value) {
    Map<String, Object> model = new HashMap<>();
    model.put(key, value);
    return render(templatePath, model);
  }
}
