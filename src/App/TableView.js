"use strict"

import * as d3 from "d3"

// This prelude currently duplicated across all FFI implementations.
function curry2(f) {
   return x1 => x2 => f(x1, x2)
}

function curry3(f) {
   return x1 => x2 => x3 => f(x1, x2, x3)
}

function curry4(f) {
   return x1 => x2 => x3 => x4 => f(x1, x2, x3, x4)
}

function val_α(v) {
   return v._1
}

function val_v(v) {
   return v._2
}

function prim (v) {
   return v._1
}

// https://stackoverflow.com/questions/5560248
function colorShade(col, amt) {
   col = col.replace(/^#/, '')
   if (col.length === 3) col = col[0] + col[0] + col[1] + col[1] + col[2] + col[2]

   let [r, g, b] = col.match(/.{2}/g);
   ([r, g, b] = [parseInt(r, 16) + amt, parseInt(g, 16) + amt, parseInt(b, 16) + amt])

   r = Math.max(Math.min(255, r), 0).toString(16)
   g = Math.max(Math.min(255, g), 0).toString(16)
   b = Math.max(Math.min(255, b), 0).toString(16)

   const rr = (r.length < 2 ? '0' : '') + r
   const gg = (g.length < 2 ? '0' : '') + g
   const bb = (b.length < 2 ? '0' : '') + b

   return `#${rr}${gg}${bb}`
}

// any record type with only primitive fields -> boolean
function isUsed (r) {
   return Object.keys(r).some(k => val_α(r[k]))
}

// Generic to all tables.
function drawTable_ (
   id,
   childIndex,
   {
      title,   // String
      filter,  // Boolean
      table    // Array of any record type with only primitive fields
   },
   listener
) {
   return () => {
      const childId = id + '-' + childIndex
      const cellFill = '#ffffff'
      const div = d3.select('#' + id)

      indexKey = "__n"
      table = table.map((r, n) => { return {[ indexKey ]: n + 1, ...r} })

      div.selectAll('#' + childId).remove()
      if (filter) {
         table = table.filter(r => isUsed(r))
      }

      if (table.length > 0) {
         const HTMLtable = div
            .append('table')
            .attr('id', childId)

         const colNames = Object.keys(table[0])

         HTMLtable.append('caption')
            .text(title)
            .attr('x', 0)
            .attr('y', 0)
            .attr('class', 'title-text table-caption')
            .attr('dominant-baseline', 'middle')
            .attr('text-anchor', 'left')

         const tableHead = HTMLtable.append('thead')
         tableHead
            .append('tr')
            .selectAll('th')
            .data(colNames)
            .enter()
            .append('th')
            .text(d => d == indexKey ? (filter ? "▸" : "▾" ) : d)

         const rows = HTMLtable
            .append('tbody')
            .selectAll('tr')
            .data(table)
            .enter()
            .append('tr')

         rows.selectAll('td')
            .data(d => colNames.map(k => { return { 'value': d[k], 'name': k } }))
            .enter()
            .append('td')
            .attr('data-th', d => d.name)
            .attr('class', d => d.name != indexKey && val_α(d.value) ? 'cell-selected' : null)
            .attr('bgcolor', d => d.name != indexKey && val_α(d.value) ? colorShade(cellFill, -40) : cellFill)
            .text(d => d.name != indexKey ? prim(val_v(d.value)) : d.value)
            .on('mousedown', e => listener(e))

         sel = d3.select("th")
         sel.on("mouseover", (d, i) => console.log("TODO: toggle filter state persistently"))
      }
   }
}

export var drawTable = curry4(drawTable_)
