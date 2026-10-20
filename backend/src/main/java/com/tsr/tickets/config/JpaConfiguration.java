package com.tsr.tickets.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@Configuration
@EnableJpaAuditing
public class JpaConfiguration {
}

// Auditing → automatically track create/update information

//orm.xml → old/global configuration approach - currently we are using this approach
// BaseEntity + @EntityListeners → cleaner approach

//@MappedSuperclass
//@EntityListeners(AuditingEntityListener.class)
//public abstract class BaseEntity {
//
//    @CreatedDate
//    private LocalDateTime createdAt;
//
//    @LastModifiedDate
//    private LocalDateTime updatedAt;
//}

// Then

//@Entity
//public class Event extends BaseEntity {
//    // fields
//}