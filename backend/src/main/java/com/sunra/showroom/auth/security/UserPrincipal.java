package com.sunra.showroom.auth.security;

import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

@Getter
public class UserPrincipal implements UserDetails {

    private final Integer userId;
    private final String username;
    private final String password;
    private final String fullName;
    private final String email;
    private final String roleName;
    private final boolean active;
    private final boolean nonLocked;
    private final Collection<? extends GrantedAuthority> authorities;

    public UserPrincipal(Integer userId,
                         String username,
                         String password,
                         String fullName,
                         String email,
                         String roleName,
                         boolean active,
                         boolean nonLocked) {
        this.userId = userId;
        this.username = username;
        this.password = password;
        this.fullName = fullName;
        this.email = email;
        this.roleName = roleName;
        this.active = active;
        this.nonLocked = nonLocked;

        // Map database role to standard Spring Security authority prefix
        String authority = roleName.startsWith("ROLE_") ? roleName : "ROLE_" + roleName;
        this.authorities = Collections.singletonList(new SimpleGrantedAuthority(authority));
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return nonLocked;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return active;
    }
}
