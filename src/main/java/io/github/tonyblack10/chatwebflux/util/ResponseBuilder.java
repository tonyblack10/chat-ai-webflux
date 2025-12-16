package io.github.tonyblack10.chatwebflux.util;

import java.util.HashMap;
import java.util.Map;

/**
 * Utility class for building standardized response maps.
 * Helps eliminate code duplication in controller response creation.
 */
public class ResponseBuilder {

  /**
   * Creates a success response with a message
   * @param message Success message
   * @return Map containing success flag and message
   */
  public static Map<String, Object> success(String message) {
    Map<String, Object> response = new HashMap<>();
    response.put("success", true);
    response.put("message", message);
    return response;
  }

  /**
   * Creates a success response without a message, only success flag and data
   * @param key Data key
   * @param value Data value
   * @return Map containing success flag and data
   */
  public static Map<String, Object> successWithData(String key, Object value) {
    Map<String, Object> response = new HashMap<>();
    response.put("success", true);
    response.put(key, value);
    return response;
  }

  /**
   * Creates a success response with a message and additional data
   * @param message Success message
   * @param key Additional data key
   * @param value Additional data value
   * @return Map containing success flag, message, and additional data
   */
  public static Map<String, Object> success(String message, String key, Object value) {
    Map<String, Object> response = success(message);
    response.put(key, value);
    return response;
  }

  /**
   * Creates an error response with a message
   * @param message Error message
   * @return Map containing success flag (false) and error message
   */
  public static Map<String, Object> error(String message) {
    Map<String, Object> response = new HashMap<>();
    response.put("success", false);
    response.put("message", message);
    return response;
  }

  /**
   * Creates a conditional response based on a boolean flag
   * @param condition Condition to evaluate
   * @param successMessage Message to use if condition is true
   * @param errorMessage Message to use if condition is false
   * @return Map containing success flag and appropriate message
   */
  public static Map<String, Object> conditional(boolean condition, String successMessage, String errorMessage) {
    return condition ? success(successMessage) : error(errorMessage);
  }
}
