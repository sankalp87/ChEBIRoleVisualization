/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.testapp;

/**
 *
 * @author sankalp
 */
import com.apple.jobjc.Utils.Strings;
import java.io.FileWriter;
import java.io.IOException;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import org.apache.log4j.Logger;
import uk.ac.ebi.chebi.webapps.chebiWS.client.ChebiWebServiceClient;
import uk.ac.ebi.chebi.webapps.chebiWS.model.*;

/**
 *
 *
 */
public class ChebiTreeJson {
   
public static int totalChildrenCount=0;
private static final Logger logger = Logger.getLogger(ChebiTreeJson.class);
private String chebiId = "";

public void setChebiId(String chebiId) {
        this.chebiId = chebiId;
    }
    /**
     * @param args the command line arguments
     * @throws java.io.IOException
     */
    

    public static void generateFile(Integer id, String path) throws IOException {
        ChebiWebServiceClient client = new ChebiWebServiceClient();
       // System.out.println("enter the chebi id");
        String fpath = path+"/chebi_"+id+".json";
        FileWriter writer = new FileWriter(new File(fpath));
        writer.write("{");

        try {

            String chebiId = id.toString();

            int treeHeight = 0;

            Entity entity = client.getCompleteEntity(chebiId);

            writer.write("\n     \"chebi_id\": \"" + entity.getChebiId() + "\",");
            writer.write("\n     \"name\": \"" + entity.getChebiAsciiName() + "\",");
            writer.write("\n     \"definition\": \"" + entity.getDefinition() + "\",");
            String formula = null;    
                            List<DataItem> formulaeList = entity.getFormulae();
                    if (formulaeList != null && formulaeList.size() > 0) {
                        formula=formulaeList.get(0).getData();
                    }
            writer.write("\n     \"formula\": \"" + formula + "\",");
            writer.write("\n     \"mass\": \"" + entity.getMass() + "\",");
            writer.write("\n     \"TotalChildrenCount\": \"" + countChildren(client, entity.getChebiId()) + "\",");
           // writer.write("\n     \"ChildrenWordLength\": \"" + maxWordLengthChildren(client, entity.getChebiId()) + "\",");
            writer.write("\n     \"url\": \"http://www.ebi.ac.uk/chebi/searchId.do;45D01B98B7315EDB33546A484BCC4046?chebiId=" + entity.getChebiId() + "\",");
            writer.write("\n     \"imageUrl\": \"http://www.ebi.ac.uk/chebi/displayImage.do?defaultImage=true&imageIndex=0&chebiId=" + entity.getChebiId() + "&dimensions=" + "\",");
            writer.write("\n     \"data\": {},");
            writer.write("\n     \"children\": [");
            findChildren(client, chebiId, entity.getChebiAsciiName(), writer, treeHeight);
            writer.write("]\n }");

        } catch (ChebiWebServiceFault_Exception e) {
            System.err.println("Oops! Something went wrong..." + e.getMessage());

            // clean up the file operations
        } finally {
            writer.close();
        }

        //Utility.JSON.resolveJsonChildren(fpath);

    }

    private static int findChildren(ChebiWebServiceClient client, String chebiId, String chebiName, FileWriter writer, int treeHeight) throws ChebiWebServiceFault_Exception, IOException {
        OntologyDataItemList lists = client.getOntologyChildren(chebiId);
        List<OntologyDataItem> results = lists.getListElement();
        ++treeHeight;
        int value = 0;
        int size = 0;
        int size_isa = 0;
        int size_hasrole = 0;
        boolean hasChildren = false;

        // we have more than one child
        if (results.size() > 0) {
            for (int iii = 0; iii < results.size(); iii++) {

                OntologyDataItem result = results.get(iii);

                if (!result.isCyclicRelationship()) {
                    if (result.getType().equals("is a") || result.getType().equals("has role")) {

                        LiteEntityList allInPath_isa = client.getAllOntologyChildrenInPath(result.getChebiId(), RelationshipType.IS_A, true);
                        LiteEntityList allInPath_hasrole = client.getAllOntologyChildrenInPath(result.getChebiId(), RelationshipType.HAS_ROLE, true);
                        size_isa = allInPath_isa.getListElement().size();
                        size_hasrole = allInPath_hasrole.getListElement().size();
                        size = size_isa + size_hasrole;

                        if (size >= 0) {

                            if (hasChildren == true) {
                                writer.write(",");
                            }

                            Entity child = client.getCompleteEntity(result.getChebiId());
                           // System.out.println(child.getDefinition());
                            String definition = child.getDefinition();
                            if (definition.contains("\"")) {
                                definition = definition.replaceAll("\"", "\\\\\"");
                            }

                            writer.write("{ \n         \"chebi_id\": \"" + result.getChebiId() + "\",   \n"
                                    + "         \"name\": \"" + result.getChebiName() + "\",  \n"
                                    + "         \"data\": {},");
                            writer.write("\n     \"definition\": \"" + definition + "\",");
                            String formula = null;    
                            List<DataItem> formulaeList = child.getFormulae();
                    if (formulaeList != null && formulaeList.size() > 0) {
                        formula=formulaeList.get(0).getData();
                    }
                      
                            
                            writer.write("\n     \"formula\": \"" + formula + "\",");
                           
                           
                                writer.write("\n     \"mass\": \"" + child.getMass() + "\",");
                            totalChildrenCount=0;
                            writer.write("\n     \"TotalChildrenCount\": \"" + countChildren(client, result.getChebiId()) + "\",");
                           // writer.write("\n     \"ChildrenWordLength\": \"" + maxWordLengthChildren(client, result.getChebiId()) + "\",");
                            writer.write("\n \"role\": \"" + result.getType().toUpperCase() + "\" ,");
                            writer.write("\n     \"url\": \"http://www.ebi.ac.uk/chebi/searchId.do;45D01B98B7315EDB33546A484BCC4046?chebiId=" + result.getChebiId() + "\",");
                            writer.write("\n     \"imageUrl\": \"http://www.ebi.ac.uk/chebi/displayImage.do?defaultImage=true&imageIndex=0&chebiId=" + result.getChebiId() + "&dimensions=" + "\",");
                            writer.write("\n    \"children\": [");
                          //  System.out.println("Checking for children of: " + result.getChebiName());

                            value = findChildren(client, result.getChebiId(), result.getChebiName(), writer, treeHeight);

                            hasChildren = true;
                            if (hasChildren == true) {
                                writer.write("]\n}");
                            }

                        }

                    }

                }
                if (iii == (results.size() - 1)) {
                    value = treeHeight + 1;
                    hasChildren = false;
                }

            }

        }

        return value;

    }

    public static int countChildren(ChebiWebServiceClient client, String ChebiId1) throws ChebiWebServiceFault_Exception {
       
        String chebiId = ChebiId1;
        Entity entity = client.getCompleteEntity(chebiId);
        OntologyDataItemList lists = client.getOntologyChildren(chebiId);
        List<OntologyDataItem> results = lists.getListElement();
        //int totalChildren = results.size();
        //totalChildrenCount=totalChildrenCount+totalChildren;

        if (results.size() > 0) {
            for (int i = 0; i < results.size(); i++) {

                OntologyDataItem result = results.get(i);
                if (result.getType().equals("is a") || result.getType().equals("has role")) {
                    //System.out.println(result.getChebiId());
                    totalChildrenCount++;
                    countChildren(client, result.getChebiId());
                }
            }

        }
        return totalChildrenCount;

    }

    public static int maxWordLengthChildren(ChebiWebServiceClient client, String ChebiId1) throws ChebiWebServiceFault_Exception {

        String chebiId = ChebiId1;
        Entity entity = client.getCompleteEntity(chebiId);
        OntologyDataItemList lists = client.getOntologyChildren(chebiId);
        List<OntologyDataItem> results = lists.getListElement();
        int maxLength = 0;
        List<Integer> name = new ArrayList<Integer>();
        if (results.size() > 0) {
            for (int i = 0; i < results.size(); i++) {

                OntologyDataItem result = results.get(i);
                if (result.getType().equals("is a") || result.getType().equals("has role")) {
                    name.add(result.getChebiName().length());
                }

            }

        }
        for (int a : name) {
            if (maxLength < a) {
                maxLength = a;
            }
        }

        return maxLength;

    }

}

