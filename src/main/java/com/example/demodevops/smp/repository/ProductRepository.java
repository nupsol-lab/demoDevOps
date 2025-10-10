package com.example.demodevops.smp.repository;

import com.example.demodevops.smp.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<Product,Long> {
}
