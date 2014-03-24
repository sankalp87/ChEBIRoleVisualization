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
import java.io.FileWriter;
import java.io.IOException;

/**
 *
 * @author sankalp
 */
public class Utility {

    public static class JSON {

        public static void resolveJsonChildren(String jSonFilePath) throws IOException {
            File jsonFile = new File(jSonFilePath);
            String textFileName = jSonFilePath.substring(0, jSonFilePath.lastIndexOf('.'));
            String newtextFileName = textFileName.concat(".txt");
            File textFile = new File(newtextFileName);
            boolean success = jsonFile.renameTo(textFile);
            if (success) {
                String jSonText = readFileAsString(textFile);
                if (jSonText.contains("\"children\": []")) {

                    File newTextFile = new File(textFileName.concat("_new.txt"));
                    saveStringAsFile(jSonText, newTextFile);
                    String newJSonText = readFileAsString(newTextFile);
                    String finalJsonText = newJSonText.replaceAll(",     \\\"children\\\"?: \\[\\]", "");
                    File finalTextFile = new File(textFileName.concat("_final.txt"));
                    saveStringAsFile(finalJsonText, finalTextFile);
                    File finalJsonFile = new File(textFileName.concat("_final.json"));
                    finalTextFile.renameTo(finalJsonFile);

                }
            }

        }

        public static String readFileAsString(File file) throws FileNotFoundException, IOException {
            final String WORD_BREAK = " ";
            StringBuilder content = new StringBuilder();
            String line = null;
            BufferedReader br = new BufferedReader(new FileReader(file));
            while ((line = br.readLine()) != null) {
                content.append(line).append(WORD_BREAK);
            }
            br.close();
            return content.toString();
        }

        public static void saveStringAsFile(String textToSave, File file) throws IOException {

            FileWriter fr = new FileWriter(file);

            fr.write(textToSave);
            fr.close();
        }

        private JSON() {

        }
    }

}
