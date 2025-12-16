package io.github.tonyblack10.chatwebflux.util;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ResponseBuilderTest {

  @Test
  void testSuccessWithMessage() {
    Map<String, Object> response = ResponseBuilder.success("Operation completed");

    assertEquals(true, response.get("success"));
    assertEquals("Operation completed", response.get("message"));
  }

  @Test
  void testSuccessWithMessageAndData() {
    Map<String, Object> response = ResponseBuilder.success("Files processed", "files", 5);

    assertEquals(true, response.get("success"));
    assertEquals("Files processed", response.get("message"));
    assertEquals(5, response.get("files"));
  }

  @Test
  void testError() {
    Map<String, Object> response = ResponseBuilder.error("Something went wrong");

    assertEquals(false, response.get("success"));
    assertEquals("Something went wrong", response.get("message"));
  }

  @Test
  void testConditionalTrue() {
    Map<String, Object> response = ResponseBuilder.conditional(
        true, 
        "Success message", 
        "Error message"
    );

    assertEquals(true, response.get("success"));
    assertEquals("Success message", response.get("message"));
  }

  @Test
  void testConditionalFalse() {
    Map<String, Object> response = ResponseBuilder.conditional(
        false, 
        "Success message", 
        "Error message"
    );

    assertEquals(false, response.get("success"));
    assertEquals("Error message", response.get("message"));
  }
}
