/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.testapp;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import javax.servlet.ServletContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

/**
 *
 * @author sankalp
 */
@Controller
public class SmartController {

    @Autowired
    ServletContext servletContext;

    @RequestMapping(value = "/{id}", method = RequestMethod.GET)
    public String data(@PathVariable Integer id, ModelMap model) throws FileNotFoundException, IOException 
    {
        if (id == null)
            return "smart";
        
       // String rootDir = servletContext.getRealPath("/WEB-INF/files/");
        String rootDir = "/Users/sankalp/Desktop/testwebapp";
        File file = new File(rootDir+"/chebi_" + id + ".json");
        
        if (!file.exists())
            ChebiTreeJson.generateFile(id, rootDir);
        
        StringBuilder sb = new StringBuilder();
        BufferedReader fw = new BufferedReader(new FileReader(file));
        String s = null;
        while ((s = fw.readLine()) != null) {
            sb.append(s + "\n");
        }
        fw.close();
        model.addAttribute("message", sb.toString());
        return "smart";
    }

    @RequestMapping(value = "/index", method = RequestMethod.GET)
    public String show(ModelMap model) 
    {
        return "visualization";
    }

}
