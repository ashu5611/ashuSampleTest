package com.example.ashu.ashutest;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
@EnableJpaRepositories
public class AshutestApplication {
	@Autowired
	BookRepo bookRepo;

	public static void main(String[] args) {
		SpringApplication.run(AshutestApplication.class, args);
	}

	@GetMapping("/hello")
	public String sayHello(@RequestParam(value = "myName", defaultValue = "World") String name) {
		System.out.println("testing");
		return String.format("Hello %s!", name);
	}

    @GetMapping("/create")
    public void create(@RequestParam(value = "id", defaultValue = "World") int id) {
        bookRepo.save(new Book(id, "Book 1"));
    }

	@GetMapping("/create")
	public List<Book> getAll() {
		return bookRepo.findAll();
	}



	


}
