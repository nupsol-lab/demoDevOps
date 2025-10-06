package com.example.demodevops.ccp.repository;

import com.example.demodevops.ccp.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CustomerRepository extends JpaRepository<Customer,Long> {
}
