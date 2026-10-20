package com.tsr.tickets.config;

import com.tsr.tickets.filters.UserProvisioningFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;
import org.springframework.security.web.SecurityFilterChain;

//    filterChain()
//     │
//             ├── 1. Protect all endpoints
//     │
//             ├── 2. Disable CSRF
//     │
//             ├── 3. No session → STATELESS
//     │
//             ├── 4. Enable JWT authentication
//     │
//             ├── 5. Add UserProvisioningFilter
//     │
//             └── 6. Build security configuration

@Configuration
public class SecurityConfig {

    // Defines the Spring Security filter chain.
    // HttpSecurity → used to configure Spring Security.
    // UserProvisioningFilter → our custom filter.
    @Bean
    public SecurityFilterChain filterChain(
            HttpSecurity http,
            UserProvisioningFilter userProvisioningFilter,
            JwtAuthenticationConverter jwtAuthenticationConverter) throws Exception{
        http
                // Every API request requires an authenticated user.
                // No endpoint is publicly accessible with this rule.
                .cors(Customizer.withDefaults())
                .authorizeHttpRequests(authorize->
                            authorize
                                    .requestMatchers(HttpMethod.GET, "/api/v1/published-events/**").permitAll()
                                    .requestMatchers("/api/v1/events").hasRole("ORGANIZER")
                                    .requestMatchers("/api/v1/ticket-validations").hasRole("STAFF")
                                    .requestMatchers("/test","/swagger-ui/**",
                                            "/swagger-ui.html",
                                            "/v3/api-docs/**").permitAll()
                                    .anyRequest().authenticated()
                )
                // Disable CSRF because this is a stateless REST API
                // using Bearer tokens instead of browser sessions.
                .csrf(csrf->csrf.disable())
                // Don't create/store HTTP sessions.
                // Every request must provide its JWT.
                .sessionManagement(session->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // Configure this application as an OAuth2 Resource Server.
                // Spring Security will validate JWT access tokens
                // issued by Keycloak.
                .oauth2ResourceServer(oauth2->
                        oauth2.jwt(jwt->
                                jwt.jwtAuthenticationConverter(jwtAuthenticationConverter)
                        ))
                // Run our UserProvisioningFilter AFTER
                // Spring's BearerTokenAuthenticationFilter.
                //
                // Why?
                // BearerTokenAuthenticationFilter first validates the
                // Keycloak JWT and creates the Authentication object.
                // Then our filter can read that authenticated user.
                .addFilterAfter(userProvisioningFilter, BearerTokenAuthenticationFilter.class);
        // Build and return the configured security filter chain.
        return http.build();
    }

}
