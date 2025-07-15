package io.github.tonyblack10.chatwebflux;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestClient;

@SpringBootApplication
public class ChatWebfluxApplication {

	public static void main(String[] args) {
		SpringApplication.run(ChatWebfluxApplication.class, args);
	}

	@Bean
	public RestClient.Builder restClientBuilder() {
		return RestClient.builder();
	}

}
