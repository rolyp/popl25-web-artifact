x = '''let image' = [[15, 13, 6, 9, 16], [12, 5, 15, 4, 13], [14, 9, 20, 8, 1], [4, 10, 3, 7, 19], [3, 11, 15, 2, 9]];
      image = [|nth2 i j image'|(i, j) in (5, 5)|];
      pair = ⸨(⸨100⸩, ⸨200⸩)⸩ in
  matrixUpdate image ((2, 2)) pair'''
y = '''let image' = [[15, 13, 6, 9, 16], [12, 5, 15, 4, 13], [14, 9, 20, 8, 1], [4, 10, 3, 7, 19], [3, 11, 15, 2, 9]];
      image = [|nth2 i j image'|(i, j) in (5, 5)|];
      pair = ⸨(⸨100⸩, ⸨200⸩)⸩ in
  matrixUpdate image ((2, 2)) pair'''

print (x == y)
