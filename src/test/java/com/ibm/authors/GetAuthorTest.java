package com.ibm.authors;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import javax.json.JsonObject;
import static org.junit.jupiter.api.Assertions.*;



class GetAuthorTest {

    @Test
    @DisplayName("should return the json format")
    void testCreateJson() {

        Author author = new Author("Vlad Sancira","none","https://github.com/vladsancira/");

        GetAuthor getAuthor = new GetAuthor();

        JsonObject json_author;
        json_author = getAuthor.createJson(author);



        assertEquals(json_author.getString("name"),author.name
                );
    }

}