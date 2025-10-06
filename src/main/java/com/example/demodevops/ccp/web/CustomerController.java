package com.example.demodevops.ccp.web;

import com.example.demodevops.ccp.entity.Customer;
import com.example.demodevops.ccp.repository.CustomerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/customers")
public class CustomerController {

    private final CustomerRepository customerRepository;

    @GetMapping
    public List<Customer> findAll() {
        return customerRepository.findAll();
    }

    @PostMapping
    public Customer create(@RequestBody Customer customer) {
        return customerRepository.save(customer);
    }

    @GetMapping("/{id}")
    public Customer findById(@PathVariable Long id) {
        return customerRepository.findById(id).orElseThrow();
    }

    @PutMapping("/{id}")
    public Customer update(@PathVariable Long id, @RequestBody Customer customer) {
        customer.setId(id);
        return customerRepository.save(customer);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        customerRepository.deleteById(id);
    }


}
