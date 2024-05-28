package com.example.ashu.ashutest;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "book")
public class Book {

    @Id
    private int id;
    private String title;

    public Book() {
    }

    public Book(int i, String s) {
            this.id = i;
            this.title = s;
    }

}
