package com.tsr.tickets.config;


import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Component
// Tells Spring to create and manage an object of this class.
// Because of this, Spring can automatically use this converter
// in the Security configuration.

public class JwtAuthenticationConverter
        implements Converter<Jwt, JwtAuthenticationToken> {

    @Override
    // We override the convert() method from Spring's Converter interface.

    public JwtAuthenticationToken convert(Jwt jwt) {

        // Extract roles/authorities from the JWT token.
        Collection<GrantedAuthority> authorities = extractAuthorities(jwt);

        // Create a JwtAuthenticationToken.
        //
        // jwt          -> the original JWT
        // authorities  -> roles/permissions extracted from the JWT
        //
        // Spring Security will use these authorities to decide
        // whether the user is allowed to access an endpoint.
        return new JwtAuthenticationToken(jwt, authorities);
    }


    private Collection<GrantedAuthority> extractAuthorities(Jwt jwt) {

        // Keycloak usually puts realm-level roles inside the JWT like:
        //
        // "realm_access": {
        //     "roles": [
        //         "ROLE_USER",
        //         "ROLE_ADMIN"
        //     ]
        // }
        //
        // Here we get the "realm_access" object from the JWT.
        Map<String, Object> realmAccess = jwt.getClaim("realm_access");


        // Check whether:
        //
        // 1. realm_access does not exist
        // OR
        // 2. realm_access does not contain "roles"
        //
        // If there are no roles, return an empty list.
        if (null == realmAccess || !realmAccess.containsKey("roles")) {
            return Collections.emptyList();
        }


        // Get the "roles" value from realm_access.
        //
        // Keycloak returns it as an Object, so we cast it to:
        // List<String>
        //
        // Example:
        //
        // ["ROLE_USER", "ROLE_ADMIN"]
        //
        @SuppressWarnings("unchecked")
        List<String> roles = (List<String>) realmAccess.get("roles");


        // Convert each Keycloak role into a Spring Security authority.
        return roles.stream()

                // Only accept roles that start with "ROLE_".
                //
                // Example:
                // "ROLE_ADMIN" -> accepted
                // "ROLE_USER"  -> accepted
                // "admin"      -> ignored
                .filter(role -> role.startsWith("ROLE_"))

                // Convert:
                //
                // "ROLE_ADMIN"
                //
                // into:
                //
                // new SimpleGrantedAuthority("ROLE_ADMIN")
                //
                // Spring Security understands SimpleGrantedAuthority.
                .map(SimpleGrantedAuthority::new)

                // Convert the Stream back into a List.
                .collect(Collectors.toList());
    }
}