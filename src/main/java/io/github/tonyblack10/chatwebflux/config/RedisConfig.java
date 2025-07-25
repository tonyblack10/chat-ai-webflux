package io.github.tonyblack10.chatwebflux.config;

import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.TokenCountBatchingStrategy;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.ai.vectorstore.redis.RedisVectorStore;
import org.springframework.ai.vectorstore.redis.RedisVectorStore.MetadataField;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.ReactiveRedisConnectionFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.util.Map;
import redis.clients.jedis.JedisPooled;

@Configuration
public class RedisConfig {

    @Bean
    public JedisPooled jedisPooled() {
        return new JedisPooled("localhost", 6379);
    }

    @Bean
    public VectorStore vectorStore(JedisPooled jedisPooled, EmbeddingModel embeddingModel) {
      return RedisVectorStore.builder(jedisPooled, embeddingModel)
          .indexName("custom-index")                // Optional: defaults to "spring-ai-index"
          .prefix("custom-prefix")                  // Optional: defaults to "embedding:"
          .initializeSchema(true)                   // Optional: defaults to false
          .batchingStrategy(new TokenCountBatchingStrategy()) // Optional: defaults to TokenCountBatchingStrategy
          .build();
    }

    @Bean
    public ReactiveRedisTemplate<String, Map<String, String>> reactiveRedisTemplate(
            ReactiveRedisConnectionFactory factory) {

        StringRedisSerializer keySerializer = new StringRedisSerializer();
       Jackson2JsonRedisSerializer<Map<String, String>> valueSerializer =
               new Jackson2JsonRedisSerializer<>((Class<Map<String, String>>) (Class<?>) Map.class);

        RedisSerializationContext.RedisSerializationContextBuilder<String, Map<String, String>> builder =
                RedisSerializationContext.newSerializationContext(keySerializer);

        RedisSerializationContext<String, Map<String, String>> context =
                builder.value(valueSerializer).build();

        return new ReactiveRedisTemplate<>(factory, context);
    }
}
