-- Linear-algebra calculator definitions.

local function inputs2(prefix)
    return {{label=prefix.."11"},{label=prefix.."12"},{label=prefix.."21"},{label=prefix.."22"}}
end

local function twoMatrixInputs()
    local result = inputs2("A")
    local second = inputs2("B")
    for _, item in ipairs(second) do result[#result + 1] = item end
    return result
end

local function outputs2(prefix)
    return {{label=prefix.."11"},{label=prefix.."12"},{label=prefix.."21"},{label=prefix.."22"}}
end

local function unpack2(a) return a[1][1], a[1][2], a[2][1], a[2][2] end
local function yesNo(value) return value ~= 0 and "YES" or "NO" end

function registerLinearAlgebraCalculators(calculators)
    calculators.matrixAdd2 = Calculator.new({id="matrixAdd2",title="Matrix Addition 2x2",inputs=twoMatrixInputs(),outputs=outputs2("C"),calculate=function(v) return unpack2(matrix.add(matrix.fromFlat(v,2,2,1),matrix.fromFlat(v,2,2,5))) end})
    calculators.matrixSubtract2 = Calculator.new({id="matrixSubtract2",title="Matrix Subtraction 2x2",inputs=twoMatrixInputs(),outputs=outputs2("C"),calculate=function(v) return unpack2(matrix.subtract(matrix.fromFlat(v,2,2,1),matrix.fromFlat(v,2,2,5))) end})
    calculators.matrixMultiply2 = Calculator.new({id="matrixMultiply2",title="Matrix Multiplication 2x2",inputs=twoMatrixInputs(),outputs=outputs2("C"),calculate=function(v) return unpack2(matrix.multiply(matrix.fromFlat(v,2,2,1),matrix.fromFlat(v,2,2,5))) end})
    calculators.matrixVector2 = Calculator.new({id="matrixVector2",title="Matrix-Vector Product 2x2",inputs={{label="A11"},{label="A12"},{label="A21"},{label="A22"},{label="x1"},{label="x2"}},outputs={{label="y1"},{label="y2"}},calculate=function(v) return v[1]*v[5]+v[2]*v[6],v[3]*v[5]+v[4]*v[6] end})
    calculators.matrixScalar2 = Calculator.new({id="matrixScalar2",title="Scalar Multiplication 2x2",inputs={{label="Scalar k"},{label="A11"},{label="A12"},{label="A21"},{label="A22"}},outputs=outputs2("C"),calculate=function(v) return unpack2(matrix.scalarMultiply(v[1],matrix.fromFlat(v,2,2,2))) end})
    calculators.matrixTranspose2 = Calculator.new({id="matrixTranspose2",title="Matrix Transpose 2x2",inputs=inputs2("A"),outputs=outputs2("T"),calculate=function(v) return unpack2(matrix.transpose(matrix.fromFlat(v,2,2,1))) end})
    calculators.matrixDet2 = Calculator.new({id="matrixDet2",title="Determinant 2x2",inputs=inputs2("A"),outputs={{label="det(A)"}},calculate=function(v) return matrix.det2(matrix.fromFlat(v,2,2,1)) end})
    calculators.matrixDet3 = Calculator.new({id="matrixDet3",title="Determinant 3x3",inputs={{label="A11"},{label="A12"},{label="A13"},{label="A21"},{label="A22"},{label="A23"},{label="A31"},{label="A32"},{label="A33"}},outputs={{label="det(A)"}},visibleInputCount=5,calculate=function(v) return matrix.det3(matrix.fromFlat(v,3,3,1)) end})
    calculators.matrixInverse2 = Calculator.new({id="matrixInverse2",title="Matrix Inverse 2x2",inputs=inputs2("A"),outputs=outputs2("Inv"),validate=function(v) local inv,err=matrix.inverse2(matrix.fromFlat(v,2,2,1)); if not inv then return err end end,calculate=function(v) return unpack2(matrix.inverse2(matrix.fromFlat(v,2,2,1))) end})
    calculators.matrixTrace2 = Calculator.new({id="matrixTrace2",title="Matrix Trace 2x2",inputs=inputs2("A"),outputs={{label="tr(A)"}},calculate=function(v) return v[1]+v[4] end})
    calculators.matrixTrace3 = Calculator.new({id="matrixTrace3",title="Matrix Trace 3x3",inputs={{label="A11"},{label="A12"},{label="A13"},{label="A21"},{label="A22"},{label="A23"},{label="A31"},{label="A32"},{label="A33"}},outputs={{label="tr(A)"}},visibleInputCount=5,calculate=function(v) return v[1]+v[5]+v[9] end})

    calculators.matrixProperties2 = Calculator.new({
        id="matrixProperties2",title="Matrix Properties 2x2",inputs=inputs2("A"),
        outputs={{label="Determinant"},{label="Trace"},{label="Rank"},{label="Singular",format=yesNo}},
        calculate=function(v)
            local a=matrix.fromFlat(v,2,2,1); local det=matrix.det2(a)
            return det,matrix.trace(a),matrix.rank2(a),math.abs(det)<1e-10 and 1 or 0
        end
    })

    calculators.matrixTests2 = Calculator.new({
        id="matrixTests2",title="Matrix Tests 2x2",inputs=inputs2("A"),
        outputs={{label="Symmetric",format=yesNo},{label="Orthogonal",format=yesNo},{label="Positive definite",format=yesNo}},
        calculate=function(v)
            local a=matrix.fromFlat(v,2,2,1)
            return matrix.isSymmetric2(a) and 1 or 0,matrix.isOrthogonal2(a) and 1 or 0,matrix.isPositiveDefinite2(a) and 1 or 0
        end
    })

    calculators.eigenvalues2 = Calculator.new({id="eigenvalues2",title="Eigenvalues 2x2",inputs=inputs2("A"),outputs={{label="lambda1 real"},{label="lambda1 imag"},{label="lambda2 real"},{label="lambda2 imag"}},calculate=function(v) return matrix.eigen2(matrix.fromFlat(v,2,2,1)) end})
    calculators.eigenvectors2 = Calculator.new({id="eigenvectors2",title="Eigenvectors 2x2",subtitle="Real, distinct eigenvalues only",inputs=inputs2("A"),outputs={{label="v1 x"},{label="v1 y"},{label="v2 x"},{label="v2 y"}},validate=function(v) local r1,i1,r2,i2=matrix.eigen2(matrix.fromFlat(v,2,2,1)); if math.abs(i1)>1e-10 or math.abs(i2)>1e-10 then return "Eigenvectors require real eigenvalues" end; if math.abs(r1-r2)<1e-10 then return "Repeated eigenvalue; eigenspace may not be unique" end end,calculate=function(v) local a=matrix.fromFlat(v,2,2,1); local l1,_,l2=matrix.eigen2(a); local x1,y1=matrix.eigenvector2(a,l1); local x2,y2=matrix.eigenvector2(a,l2); return x1,y1,x2,y2 end})
    calculators.characteristicPolynomial2 = Calculator.new({id="characteristicPolynomial2",title="Characteristic Polynomial 2x2",subtitle="lambda^2 + b lambda + c",inputs=inputs2("A"),outputs={{label="lambda^2 coefficient"},{label="lambda coefficient"},{label="constant"}},calculate=function(v) local a=matrix.fromFlat(v,2,2,1); return 1,-matrix.trace(a),matrix.det2(a) end})
    calculators.diagonalizable2 = Calculator.new({id="diagonalizable2",title="Diagonalization Check 2x2",inputs=inputs2("A"),outputs={{label="Real diagonalizable",format=yesNo},{label="Repeated eigenvalue",format=yesNo}},calculate=function(v) local a=matrix.fromFlat(v,2,2,1); local l1,i1,l2,i2=matrix.eigen2(a); local repeated=math.abs(i1)<1e-10 and math.abs(i2)<1e-10 and math.abs(l1-l2)<1e-10; local scalar=math.abs(a[1][2])<1e-10 and math.abs(a[2][1])<1e-10 and math.abs(a[1][1]-a[2][2])<1e-10; local diagonalizable=(math.abs(i1)<1e-10 and math.abs(i2)<1e-10 and (not repeated or scalar)); return diagonalizable and 1 or 0,repeated and 1 or 0 end})
end
