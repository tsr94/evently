package com.tsr.tickets.filters;

import com.tsr.tickets.domain.entity.User;
import com.tsr.tickets.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class UserProvisioningFilter extends OncePerRequestFilter {
    // This class is a custom HTTP filter.
    // OncePerRequestFilter guarantees that this filter runs once
    // for each HTTP request.

    private final UserRepository userRepository;

    // This method is called automatically by Spring Security
    // for every HTTP request that passes through this filter.
    //
    // request  -> information about incoming HTTP request
    // response -> response that will be sent to client
    // filterChain -> allows the request to continue to the next filter
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        // Get the Authentication object from Spring Security's
        // SecurityContext.
        // After Keycloak's JWT has been successfully validated,
        // Spring Security puts information about the logged-in user
        // inside this SecurityContext.
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        // Check three things:
        //
        // 1. authentication != null
        //    -> There is an authentication object.
        //
        // 2. authentication.isAuthenticated()
        //    -> Spring Security considers the user authenticated.
        //
        // 3. authentication.getPrincipal() instanceof Jwt jwt
        //    -> The authenticated user's principal is a JWT.
        //
        // "instanceof Jwt jwt" is Java pattern matching.
        // If the principal is a Jwt, Java creates a variable called
        // "jwt" containing that Jwt object.
        if (authentication != null
                && authentication.isAuthenticated()
                && authentication.getPrincipal() instanceof Jwt jwt) {

            // Get the "sub" claim from the Keycloak JWT.
            //
            // "sub" means "subject".
            // In this architecture, it represents the Keycloak user's ID.
            //
            // Example:
            //
            // sub = "550e8400-e29b-41d4-a716-446655440000"
            //
            // UUID.fromString() converts that String into a Java UUID.
            UUID keycloakId = UUID.fromString(jwt.getSubject());

            // Check whether this Keycloak user already exists
            // in OUR application's User table.
            //
            // IMPORTANT:
            //
            // Keycloak has its own user database.
            // Your event-ticket-platform database has its own User table.
            //
            // This checks the event-ticket-platform database.
            if(!userRepository.existsById(keycloakId)){
                User user = new User();
                user.setId(keycloakId);
                // Read the "preferred_username" claim from the JWT.
                //
                // Example JWT:
                //
                // "preferred_username": "shubham"
                //
                // getClaimAsString() returns it as a String.
                user.setName(jwt.getClaimAsString("preferred_username"));
                user.setEmail(jwt.getClaimAsString("email"));

                userRepository.save(user);
            }

        }
        // VERY IMPORTANT:
        //
        // Pass the request to the next filter in the Spring Security
        // filter chain.
        //
        // If you don't call this, the request can stop here and
        // never reach your controller.
        filterChain.doFilter(request,response);

    }
}
