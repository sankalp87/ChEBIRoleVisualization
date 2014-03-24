<%@page contentType="text/html" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Chebi tree Viewer</title>
<h1 style="text-align: center">
        <a href="index.do">ChEBI Role Visualization</a>
    </h1>
<style type="text/css">
body{
    margin: 0;
    font: 13px Helvetica, arial, freesans, clean, sans-serif;
    line-height: 1.4;
    background-color: dimgrey;
    height: 100%;
    width: 100%;
    overflow: hidden;
}
/*CSS - id - treecontainer (sets the properties of the tree container)*/
#treecontainer {
height: 70%;
width: 70%;
position: absolute;
top:0;
bottom: 0;
left: 0;
right: 0;
margin: auto;
background-color: #FFF;
overflow: hidden;
}
.node {
    cursor: pointer;
}

.node circle {
    fill: #fff;
    stroke: steelblue;
    stroke-width: 1.5px;
}

.node text {
    font: 12px sans-serif;
}

circle.root{
    fill: #fff;
    stroke: steelblue;
}

circle.role-is-a, circle.legend-0 {
    fill: #8a2be2 !important;
    stroke: #8a2be2 !important;
}

circle.role-has, circle.legend-1 {
    fill: #ff5454 !important;
    stroke: #ff5454 !important;
}

circle.legend-2{
    fill: green;
    stroke: green;
}

.node.highlight, .node.highlight circle{
    fill: green !important;
}
.node.highlight text{
    font-size: 16px;
}
.link {
    fill: none;
    stroke: #eee;
    stroke-width: 2px;
}
.link.highlight{
    stroke: green;
}
#legend {
position: absolute;
top: 55px;
left: 15px;
}
#btn_focus {
position: absolute;
left: 10px;
top: 10px;
}
#child_filter {
position: absolute;
top: 40px;
left: 10px;
}
.d3-tip {
    line-height: 1.4;
    font-weight: normal;
    background: #fff;
    border: solid 1px #bbb;
    color: #666;
    border-radius: 2px;
    max-width: 424px;
    pointer-events: none;
}

/* data color */
.d3-tip span{
    color: #5a6986;
}

/* link color */
.d3-tip a{
    color: green;
}

/* title color */
.d3-tip .title{
    color: #2080B6;
    font-size: 16px;
    text-transform: capitalize;
}

.d3-tip div {
    display: block;
    margin-bottom: 3px;
    border-bottom: dotted 1px #eee;
}

.d3-tip .tip-inner-wrapper{
    position: relative;
    padding: 12px;
}

.d3-tip .btn-close{
    position: absolute;
    top: 5px;
    right: 5px;
    color: #666;
}

/* Creates a small triangle extender for the tooltip */
.d3-tip:after {
    box-sizing: border-box;
    display: inline;
    font-size: 12px;
    width: 100%;
    line-height: 1;
    color: transparent;
    position: absolute;
    pointer-events: none;
}

/* Northward tooltips */
.d3-tip.n:after {
    content: "\25BC";
    margin: -3px 0 0 0;
    top: 100%;
    left: 0;
    text-align: center;
}

/* Eastward tooltips */
.d3-tip.e:after {
    content: "\25C0";
    margin: -4px 0 0 0;
    top: 50%;
    left: -8px;
}

/* Southward tooltips */
.d3-tip.s:after {
    content: "\25B2";
    margin: 0 0 1px 0;
    top: -8px;
    left: 0;
    text-align: center;
}

/* Westward tooltips */
.d3-tip.w:after {
    content: "\25B6";
    margin: -4px 0 0 -1px;
    top: 50%;
    left: 100%;
}
</style>

</head>

<body>
<div style="text-align: center">

Enter ChEBI ID:
<input type="text" id="id"/><button><a href="#" id="submit">SUBMIT</a></button>
</div>
<div id="result"></div>

<div id="treecontainer">
<div id="legend"></div>
<button id="btn_focus">Focus</button>
<label id="child_filter">
<input type="checkbox" id="toggle_children_limit" value="10">
Show all Children
</label>
</div>

<script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
<script src="http://d3js.org/d3.v3.min.js"></script>
<script src="js/d3.tip.v0.6.3.js"></script>
<script>

var margin = {top: 20, right: 120, bottom: 20, left: 120},
width = $("#treecontainer").width() - margin.right - margin.left - 20,
height = $("#treecontainer").height() - margin.top - margin.bottom - 20;

var o = {
    size: [width, height],
    x: function(d) { return d.x; },
    y: function(d) { return d.y; }
}

var i = 0,
duration = 750,
root;

var tree = d3.layout.tree()
.size([height, width]);
//.size(o.size);

var cursor_position = {
    x : 0,
    y : 0
};

var last_clicked_node;  // holds info about last clicked node

// limit the no. of child nodes a parent can have
// show 10 by default
var CHILDREN_LIMIT = getSettingsFromQueryString().nl ? 10000 : 10;

if (getSettingsFromQueryString().nl) {
    $("#toggle_children_limit").attr("checked","checked");
};

// tooltip
var tip = d3.tip()
.direction('e')
.attr('class', 'd3-tip')
.offset([0, 25])
.html(function(d) {
    
    // add more similar lines for more data
    
    var _html = "<div class='tip-inner-wrapper'>";
    
    _html += "<div><a class='title' href='"+d.url+"'>" + d.name + "</a></div>";
    _html += "<div><label><B><U>ID</U>: </B></label><a href='"+d.url+"'>" + d.chebi_id + "</a></div>";
    _html += "<div><label><B><U>Definition</U>:</B></label> <span>" + d.definition + "</span></div>";
   // _html += "<div><label><B><U>TotalChildrenCount</U>:</B></label> <span>" + d.TotalChildrenCount + "</span></div>";
    
    // not for root node
   if (d.depth) {
        _html += "<div><label><B><U>Relation</U>:</B> " + "<I>"+d.name+"</I>" + " </label>" + "<B><U>"+d.role+"</U></B>" + " <span> " +"<I>"+ d.parent.name+"</I>" + "</span></div>";
    };
    
    if (d.role === "HAS ROLE") {
        _html += "<div><label><B><U>Formula</U>:</B></label> <span>" + d.formula + "</span></div>";
        _html += "<div><label><B><U>Mass</U>:</B></label> <span>" + d.mass + "</span></div>";
        _html += "<div><img src='" + d.imageUrl +"200"+ "'/></div>";
    };
    
    // add close button
    _html += "<a class='btn-close' onclick='tip.hide(); return false;' href='javascript:;'>X</a>";
    
    _html += "</div>";
    
    return _html;
    
});

var drag = d3.behavior.drag()
.on("drag", function(d,i) {
    
    cursor_position.x += d3.event.dx
    cursor_position.y += d3.event.dy
    
    d3.select("#vizContainer").attr("transform", function(d,i){
        return "translate(" + [ cursor_position.x,cursor_position.y ] + ")"
    })
});

var diagonal = d3.svg.diagonal()
.projection(function(d) { return [d.y, d.x]; });
//.projection(function(d) { return [o.x(d), o.y(d)]; });

var svg = d3.select("#treecontainer").append("svg")
.attr("width", width + margin.right + margin.left)
.attr("height", height + margin.top + margin.bottom);

svg.append("rect")
.attr("id","baseRect")
.attr("width", width + margin.right + margin.left)
.attr("height", height + margin.top + margin.bottom)
.style("fill", "transparent")
.call(drag);

svg = svg
.append("g")
.attr("id", "vizContainer")
.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

svg.call(tip);
/*
d3.json("chebi_16_final.json", function(error, flare) {
    
    flare.children.sort(compare);
    flare.children = flare.children.splice(0, CHILDREN_LIMIT);
    
    // filter nodes
    filterNodes(flare.children);
    
    //console.log("flare", flare);
    
    root = flare;
    root.x0 = height / 2;
    //root.x0 = width / 2;
    root.y0 = 20;
    
    // update default position of the viz
    cursor_position.x = root.x0;
    cursor_position.y = root.y0;
    
    function collapse(d) {
        if (d.children) {
            d._children = d.children;
            d._children.forEach(collapse);
            d.children = null;
        }
    }
    
    root.children.forEach(collapse);
    // collapse the root node
    // collapse(root);
    
    update(root);
    
    // center the root node
    centerNode(root);
});
*/
function centerNode(source) {
    
    last_clicked_node = source;
    
    var scale = 1,
    x = -source.y0,
    y = -source.x0,
    x = x * scale + (width + margin.left + margin.right) / 2,
    y = y * scale + (height + margin.top + margin.bottom) / 2;
    
    d3.select("#vizContainer").transition()
    .duration(750)
    .attr("transform", "translate(" + x + "," + y + ")");
    
    // update coords
    cursor_position.x = x;
    cursor_position.y = y;
};

function update(source) {
    
    // Compute the new height, function counts total children of root node and sets tree height accordingly.
    // This prevents the layout looking squashed when new nodes are made visible or looking sparse when nodes are removed
    // This makes the layout more consistent.
    var levelWidth = [1];
    var childCount = function(level, n) {
        
        if (n.children && n.children.length > 0) {
            if (levelWidth.length <= level + 1) levelWidth.push(0);
            
            levelWidth[level + 1] += n.children.length;
            n.children.forEach(function(d) {
                childCount(level + 1, d);
            });
        }
    };
    childCount(0, root);
    var newHeight = d3.max(levelWidth) * 35; // 25 pixels per line
    tree = tree.size([newHeight, width]);
    
    // Compute the new tree layout.
    var nodes = tree.nodes(root).reverse(),
    links = tree.links(nodes);
    
    // filter nodes
    /*
     var tmp_nodes = [];
     nodes.forEach(function(d){
     if (!d.discard) {
     tmp_nodes.push(d);
     };
     });
     nodes = tmp_nodes;
     links = tree.links(nodes);
     */
    
    // Set widths between levels based on maxLabelLength.
    var maxLabelLength = 0;
    maxLabelLength = d3.max( nodes, function(d){ return d.name.length; });
    
    nodes.forEach(function(d) {
        d.y = (d.depth * (maxLabelLength * 7)); //maxLabelLength * 8px
        
        // Normalize for fixed-depth.
        //d.y = (d.depth * 180); //500px per level.
    });
    
    // Update the nodes…
    var node = svg.selectAll("g.node")
    .data(nodes, function(d) { return d.id || (d.id = ++i); });
    
    // Enter any new nodes at the parent's previous position.
    var nodeEnter = node.enter().append("g")
    .attr("class", "node")
    .attr("id", function(d,i){
        return "node-"+d.id;
    })
    .attr("transform", function(d) { return "translate(" + source.y0 + "," + source.x0 + ")"; })
    //.attr("transform", function(d) { return "translate(" + source.x0 + "," + source.y0 + ")"; })
    .on("click", click)
    .on('mouseover', tip.show);
    //.on('mouseout', tip.hide);
    
    nodeEnter.append("circle")
    .attr("r", 1e-6)
    .style("fill", function(d) { return d._children ? "steelblue" : "#fff"; })
    .attr("class", function(d) { return d.depth === 0 ? "root" : d.role == "HAS ROLE" ? "role-has" : "role-is-a" ; });
    
    nodeEnter.append("text")
    .attr("x", function(d) { return d.children || d._children ? -10 : 10; })
    .attr("dy", ".35em")
    .attr("text-anchor", function(d) { return d.children || d._children ? "end" : "start"; })
    .text(function(d) { return d.name; })
    .style("fill-opacity", 1e-6);
    
    // Transition nodes to their new position.
    var nodeUpdate = node.transition()
    .duration(duration)
    .attr("transform", function(d) { return "translate(" + d.y + "," + d.x + ")"; });
    /*.attr("transform", function(d) {
     return "translate(" + o.x(d) + "," + o.y(d) + ")";
     });*/
    
    nodeUpdate.select("circle")
    .attr("r", 4.5);
    //.style("fill", function(d) { return d._children ? "blueviolet" : "#fff"; });
    
    nodeUpdate.select("text")
    .style("fill-opacity", 1);
    
    // Transition exiting nodes to the parent's new position.
    var nodeExit = node.exit().transition()
    .duration(duration)
    .attr("transform", function(d) { return "translate(" + source.y + "," + source.x + ")"; })
    //.attr("transform", function(d) { return "translate(" + source.x + "," + source.y + ")"; })
    .remove();
    
    nodeExit.select("circle")
    .attr("r", 1e-6);
    
    nodeExit.select("text")
    .style("fill-opacity", 1e-6);
    
    // Update the links…
    var link = svg.selectAll("path.link")
    .data(links, function(d,i) { d.id = d.target.id; return d.target.id; });
    
    // Enter any new links at the parent's previous position.
    link.enter().insert("path", "g")
    .attr("class", "link")
    .attr("id", function(d,i){
        return "link-"+d.id;
    })
    .attr("d", function(d) {
        var o = {x: source.x0, y: source.y0};
        return diagonal({source: o, target: o});
    });
    
    // Transition links to their new position.
    link.transition()
    .duration(duration)
    .attr("d", diagonal);
    
    // Transition exiting nodes to the parent's new position.
    link.exit().transition()
    .duration(duration)
    .attr("d", function(d) {
        var o = {x: source.x, y: source.y};
        return diagonal({source: o, target: o});
    })
    .remove();
    
    // Stash the old positions for transition.
    nodes.forEach(function(d) {
        d.x0 = d.x;
        d.y0 = d.y;
    });
    
}

// Toggle children on click.
function click(d) {
    
    if (d.children) {
        d._children = d.children;
        d.children = null;
    } else {
        d.children = d._children;
        d._children = null;
    }
    update(d);
    
    centerNode(d);
    
    highlight(d);
    
    // hide tooltip
    tip.hide();
    
}

function highlight(source) {
    
    // remove existing highlight
    d3.selectAll(".highlight").classed("highlight", false);
    
    while (source) {
        // highlight connecting path
        d3.select("#link-"+source.id).classed("highlight", true);
        // highlight clicked node
        d3.select("#node-"+source.id).classed("highlight", true);
        
        source = source.parent ? source.parent : null;
    }
}

// sort an array; Descending by TotalChildrenCount
function compare(a,b) {
    if (+a.TotalChildrenCount < +b.TotalChildrenCount)
    return 1;
    if (+a.TotalChildrenCount > +b.TotalChildrenCount)
    return -1;
    return 0;
};

// limit number of children nodes under a parent; children are sorted by ASC
function filterNodes(arr) {
    // filter only top #CHILDREN_LIMIT child nodes of any parent node
    
    // sort nodes
    arr.sort(compare);
    
    if ( typeof(arr) == "object") {
        for (var i = 0; i < arr.length; i++) {
            var node = arr[i];
            
            if (node.children) {
                node.children.sort(compare);
            };
            
            if( node.children && node.children.length > CHILDREN_LIMIT ){
                node.children = node.children.splice(0, CHILDREN_LIMIT);
            }
            if (node.children) {
                filterNodes(node.children);
            };
        };
    };
};

// Add legend
var legend =  d3.select("#legend")
.append("svg")
.attr("width",150)
.attr("height",100)
.append("g")
.selectAll("g")
.data(['Relation : IS A', 'Relation : HAS ROLE', 'Selected'])
.enter()
.append("g","legend")
.attr("transform", function(d,i){
    return "translate(0," + (i+1)*20 + ")";
})

legend
.append("circle")
.attr("r", 4.5)
.attr("cx", "5")
.attr("class", function(d,i){
    return "legend-"+i;
});

legend.append("text")
.attr("dx","1.35em")
.attr("dy",".35em")
.text(function(d){return d;});


// if viz gets lost during drag opertaion, get back it into focus
$("#btn_focus").on("click", function(e){
    
    centerNode(last_clicked_node);
    
});

// bind with checkbox
$("#toggle_children_limit").on("change", function(e){
    if ( $(this).is(':checked') ) {
        window.location.search = 'nl=true';
    }else{
        window.location.search = '';
    };
});

/* Get URL params */
function getSettingsFromQueryString() {
    function getQueryParams(qs) {
        qs = qs.split("+").join(" ");
        var params = {};
        var tokens;
        var re = /[?&]?([^=]+)=([^&]*)/g;
        
        while (tokens = re.exec(qs)) {
            params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
        }
        
        return params;
    }
    
    var $_GET = getQueryParams(document.location.search);
    
    var result = {};
    
    for(var key in $_GET) {
        var value = $_GET[key];
        
        if(value == "null") value = null;
        else if(value == "true") value = true;
        else if(value == "false") value = false;
        else if(!isNaN(value)) value = value;//+value;
        
        result[key] = value;
    }
    
    return result;
}
$("#submit").click(function()

{

d3.json("/ChEBIRoleVisualization/"+$("#id").val()+".do", function(error, flare) {
    
    flare.children.sort(compare);
    flare.children = flare.children.splice(0, CHILDREN_LIMIT);
    
    // filter nodes
    filterNodes(flare.children);
    
    //console.log("flare", flare);
    
    root = flare;
    root.x0 = height / 2;
    //root.x0 = width / 2;
    root.y0 = 20;
    
    // update default position of the viz
    cursor_position.x = root.x0;
    cursor_position.y = root.y0;
    
    function collapse(d) {
        if (d.children) {
            d._children = d.children;
            d._children.forEach(collapse);
            d.children = null;
        }
    }
    
    root.children.forEach(collapse);
    // collapse the root node
    // collapse(root);
    
    update(root);
    
    // center the root node
    centerNode(root);
});
    return false;
});




</script>

</body>

</html>