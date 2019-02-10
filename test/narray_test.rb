require_relative "test_helper"

class NArrayTest < Test::Unit::TestCase
  types = [
    Numo::DFloat,
    Numo::SFloat,
    Numo::DComplex,
    Numo::SComplex,
    Numo::Int64,
    Numo::Int32,
    Numo::Int16,
    Numo::Int8,
    Numo::UInt64,
    Numo::UInt32,
    Numo::UInt16,
    Numo::UInt8,
  ]
  float_types = [
    Numo::DFloat,
    Numo::DComplex,
  ]

  types.each do |dtype|
    test dtype do
      assert { dtype < Numo::NArray }
    end

    procs = [
      [proc{|tp,a| tp[*a] },""],
      [proc{|tp,a| tp[*a][true] },"[true]"],
      [proc{|tp,a| tp[*a][0..-1] },"[0..-1]"]
    ]
    procs.each do |init, ref|

      test "#{dtype},[1,2,3,5,7,11]#{ref}" do
        src = [1,2,3,5,7,11]
        a = init.call(dtype, src)

        assert { a.is_a?(dtype) }
        assert { a.size == 6 }
        assert { a.ndim == 1 }
        assert { a.shape == [6] }
        assert { !a.inplace? }
        assert { a.row_major? }
        assert { !a.column_major? }
        assert { a.host_order? }
        assert { !a.byte_swapped? }
        assert { a == [1,2,3,5,7,11] }
        assert { a.to_a == [1,2,3,5,7,11] }
        assert { a.to_a.is_a?(Array) }
        assert { a.dup == a }
        assert { a.clone == a }
        assert { a.dup.object_id != a.object_id }
        assert { a.clone.object_id != a.object_id }

        assert { a.eq([1,1,3,3,7,7]) == [1,0,1,0,1,0] }
        assert { a[3..4] == [5,7] }
        assert { a[5] == 11 }
        assert { a[-1] == 11 }
        assert { a[(0..-1).each] == [1,2,3,5,7,11] }
        assert { a[(0...-1).each] == [1,2,3,5,7] }

        if Enumerator.const_defined?(:ArithmeticSequence)
          assert { a[0.step(-1)] == [1,2,3,5,7,11] }
          assert { a[0.step(4)] == [1,2,3,5,7] }
          assert { a[-5.step(-1)] == [2,3,5,7,11] }
          assert { a[0.step(-1,2)] == [1,3,7] }
          assert { a[0.step(4,2)] == [1,3,7] }
          assert { a[-5.step(-1,2)] == [2,5,11] }
        end

        assert { a[(0..-1).step(2)] == [1,3,7] }
        assert { a[(0...-1).step(2)] == [1,3,7] }
        assert { a[(0..4).step(2)] == [1,3,7] }
        assert { a[(0...4).step(2)] == [1,3] }
        assert { a[(-5..-1).step(2)] == [2,5,11] }
        assert { a[(-5...-1).step(2)] == [2,5] }
        assert { a[(0..-1) % 2] == [1,3,7] }
        assert { a[(0...-1) % 2] == [1,3,7] }
        assert { a[(0..4) % 2] == [1,3,7] }
        assert { a[(0...4) % 2] == [1,3] }
        assert { a[(-5..-1) % 2] == [2,5,11] }
        assert { a[(-5...-1) % 2] == [2,5] }
        assert { a[[4,3,0,1,5,2]] == [7,5,1,2,11,3] } #  Numo::NArray::CastError: cannot convert to NArray
        assert { a.sum == 29 }
        if float_types.include?(dtype)
          assert { a.mean == 29.0/6 }
          assert { a.var == 13.766666666666669 }
          assert { a.stddev == 3.710345895825168 }
          assert { a.rms == 5.901977069875258 }
        end
        assert { a.dup.fill(12) == [12]*6 }
        assert { (a + 1) == [2,3,4,6,8,12] }
        assert { (a - 1) == [0,1,2,4,6,10] }
        assert { (a * 3) == [3,6,9,15,21,33] }
        assert { (a / 0.5) == [2,4,6,10,14,22] }
        assert { (-a) == [-1,-2,-3,-5,-7,-11] }
        assert { (a ** 2) == [1,4,9,25,49,121] }
        assert { a.swap_byte.swap_byte == [1,2,3,5,7,11] }

        assert { a.contiguous? }
        assert { a.transpose.contiguous? }

        if dtype == Numo::DComplex || dtype == Numo::SComplex
          assert { a.real == src }
          assert { a.imag == [0]*6 }
          assert { a.conj == src }
          assert { a.angle == [0]*6 }
        else
          assert { a.min == 1 }
          assert { a.max == 11 }
          assert { a.min_index == 0 }
          assert { a.max_index == 5 }
          assert { (a >= 3) == [0,0,1,1,1,1] }
          assert { (a >  3) == [0,0,0,1,1,1] }
          assert { (a <= 3) == [1,1,1,0,0,0] }
          assert { (a <  3) == [1,1,0,0,0,0] }
          assert { (a.eq 3) == [0,0,1,0,0,0] }
          assert { a.sort == src }
          assert { a.sort_index == (0..5).to_a }
          assert { a.median == 4 }
          assert { dtype.maximum(a, 12 - a) == [11,10,9,7,7,11] }
          assert { dtype.minimum(a, 12 - a) == [1,2,3,5,5,1] }
          assert { dtype.maximum(a, 5) == [5,5,5,5,7,11] }
          assert { dtype.minimum(a, 5) == [1,2,3,5,5,5] }
        end
      end
    end

    test "#{dtype},[1..4]" do
      assert { dtype[1..4] == [1,2,3,4] }
    end

    test "#{dtype},[-4..-1]" do
      assert { dtype[-4..-1] == [-4,-3,-2,-1] }
    end

    if Enumerator.const_defined?(:ArithmeticSequence)
      test "#{dtype},[1.step(4)]" do
        assert { dtype[1.step(4)] == [1,2,3,4] }
      end

      test "#{dtype},[-4.step(-1)]" do
        assert { dtype[-4.step(-1)] == [-4,-3,-2,-1] }
      end

      test "#{dtype},[1.step(4, 2)]" do
        assert { dtype[1.step(4, 2)] == [1,3] }
      end

      test "#{dtype},[-4.step(-1, 2)]" do
        assert { dtype[-4.step(-1, 2)] == [-4,-2] }
      end

      test "#{dtype},[(-4..-1).step(2)]" do
        assert { dtype[(-4..-1).step(2)] == [-4,-2] }
      end
    end

    test "#{dtype},[(1..4) % 2]" do
      assert { dtype[(1..4) % 2] == [1,3] }
    end

    test "#{dtype},[(-4..-1) % 2]" do
      assert { dtype[(-4..-1) % 2] == [-4,-2] }
    end

    #test "#{dtype}.seq(5)" do
    #  assert { dtype.seq(5) == [0,1,2,3,4] }
    #end

    procs2 = [
      [proc{|tp,src| tp[*src] },""],
      [proc{|tp,src| tp[*src][true,true] },"[true,true]"],
      [proc{|tp,src| tp[*src][0..-1,0..-1] },"[0..-1,0..-1]"]
    ]
    procs2.each do |init, ref|

      test "#{dtype},[[1,2,3],[5,7,11]]#{ref}" do
        src = [[1,2,3],[5,7,11]]
        a = init.call(dtype, src)

        assert { a.is_a?(dtype) }
        assert { a.size == 6 }
        assert { a.ndim == 2 }
        assert { a.shape == [2,3] }
        assert { !a.inplace? }
        assert { a.row_major? }
        assert { !a.column_major? }
        assert { a.host_order? }
        assert { !a.byte_swapped? }
        assert { a == src }
        assert { a.to_a == src }
        assert { a.to_a.is_a?(Array) }

        assert { a.eq([[1,1,3],[3,7,7]]) == [[1,0,1],[0,1,0]] }
        assert { a[5] == 11 }
        assert { a[-1] == 11 }
        assert { a[1,0] == src[1][0] }
        assert { a[1,1] == src[1][1] }
        assert { a[1,2] == src[1][2] }
        assert { a[3..4] == [5,7] }
        assert { a[0,1..2] == [2,3] }
        assert { a[0,:*] == src[0] }
        assert { a[1,:*] == src[1] }
        assert { a[:*,1] == [src[0][1],src[1][1]] }
        assert { a[true,[2,0,1]] == [[3,1,2],[11,5,7]] }
        assert { a.reshape(3,2) == [[1,2],[3,5],[7,11]] }
        assert { a.reshape(3,nil) == [[1,2],[3,5],[7,11]] }
        assert { a.reshape(nil,2) == [[1,2],[3,5],[7,11]] }
        assert { a.transpose == [[1,5],[2,7],[3,11]] }
        assert { a.transpose(1,0) == [[1,5],[2,7],[3,11]] }
        assert { a.triu == [[1,2,3],[0,7,11]] }
        assert { a.tril == [[1,0,0],[5,7,0]] }

        assert { a.sum == 29 }
        assert { a.sum(0) == [6, 9, 14] }
        assert { a.sum(1) == [6, 23] }
        if float_types.include?(dtype)
          assert { a.mean == 29.0/6 }
          assert { a.mean(0) == [3, 4.5, 7] }
          assert { a.mean(1) == [2, 23.0/3] }
        end

        assert { a.contiguous? }
        assert { a.reshape(3,2).contiguous? }
        assert { a[true,1..2].contiguous? == false }
        assert { a.transpose.contiguous? == false }
        assert { a.fortran_contiguous? == false }
        assert { a.transpose.fortran_contiguous? }
        assert { a.transpose.transpose.fortran_contiguous? == false }
        assert { a.reshape(3,2).fortran_contiguous? == false }
        assert { a.reshape(3,2).transpose.fortran_contiguous? }
        assert { a[true,1..2].fortran_contiguous? == false }
        assert { a[true,1..2].transpose.fortran_contiguous? == false }

        if dtype == Numo::DComplex || dtype == Numo::SComplex
          assert { a.real == src }
          assert { a.imag == [[0]*3]*2 }
          assert { a.conj == src }
          assert { a.angle == [[0]*3]*2 }
        else
          assert { a.min == 1 }
          assert { a.max == 11 }
          assert { a.min_index == 0 }
          assert { a.min_index(axis: 1) == [0, 3] }
          assert { a.min_index(axis: 0) == [0, 1, 2] }
          assert { a.max_index(axis: 1) == [2, 5] }
          assert { a.max_index(axis: 0) == [3, 4, 5] }
          assert { (a >= 3) == [[0,0,1],[1,1,1]] }
          assert { (a >  3) == [[0,0,0],[1,1,1]] }
          assert { (a <= 3) == [[1,1,1],[0,0,0]] }
          assert { (a <  3) == [[1,1,0],[0,0,0]] }
          assert { (a.eq 3) == [[0,0,1],[0,0,0]] }
          assert { a.sort == src }
          assert { a.sort_index == [[0,1,2],[3,4,5]] }
        end
        assert { a.dup.fill(12) == [[12]*3]*2 }
        assert { (a + 1) == [[2,3,4],[6,8,12]] }
        assert { (a + [1,2,3]) == [[2,4,6],[6,9,14]] }
        assert { (a - 1) == [[0,1,2],[4,6,10]] }
        assert { (a - [1,2,3]) == [[0,0,0],[4,5,8]] }
        assert { (a * 3) == [[3,6,9],[15,21,33]] }
        assert { (a * [1,2,3]) == [[1,4,9],[5,14,33]] }
        assert { (a / 0.5) == [[2,4,6],[10,14,22]] }
        assert { (-a) == [[-1,-2,-3],[-5,-7,-11]] }
        assert { (a ** 2) == [[1,4,9],[25,49,121]] }
        assert { (dtype[[1,0],[0,1]].dot dtype[[4,1],[2,2]]) == [[4,1],[2,2]] }
        assert { a.swap_byte.swap_byte == src }
      end

    end

    test "#{dtype},[[[1,2],[3,4]],[[5,6],[7,8]]]" do
      a = dtype[[[1,2],[3,4]],[[5,6],[7,8]]]

      assert { a[0, 1, 1] == 4 }
      assert { a[:rest] == a }
      assert { a[0, :rest] == [[1,2],[3,4]] }
      assert { a[0, false] == [[1,2],[3,4]] }
      assert { a[0, 1, :rest] == [3,4] }
      assert { a[0, 1, false] == [3,4] }
      assert { a[:rest, 0] == [[1,3],[5,7]] }
      assert { a[:rest, 0, 1] == [2,6] }
      assert { a[1, :rest, 0] == [5,7] }
      assert { a[1, 1, :rest, 0] == 7 }
      assert_raise(IndexError) { a[1, 1, 1, 1, :rest] }
      assert_raise(IndexError) { a[1, 1, 1, :rest, 1] }
      assert_raise(IndexError) { a[:rest, 1, :rest, 0] }

      assert { a.transpose == [[[1,5],[3,7]],[[2,6],[4,8]]] }
      assert { a.transpose(2,1,0) == [[[1,5],[3,7]],[[2,6],[4,8]]] }
      assert { a.transpose(0,2,1) == [[[1,3],[2,4]],[[5,7],[6,8]]] }

      assert { a.contiguous? }
      assert { a.transpose.contiguous? == false }
      assert { a.fortran_contiguous? == false }
      assert { a.transpose.fortran_contiguous? }
      assert { a.transpose.transpose.fortran_contiguous? == false }
      assert { a.transpose(0,2,1).fortran_contiguous? == false }
      assert { a.reshape(2,4).fortran_contiguous? == false }
      assert { a.reshape(2,4).transpose.fortran_contiguous? }
    end

    sub_test_case "#{dtype}, #dot" do
      test "vector.dot(vector)" do
        a = dtype[1..3]
        b = dtype[2..4]
        assert { a.dot(b) == (1*2 + 2*3 + 3*4) }
      end
      test "matrix.dot(vector)" do
        a = dtype[1..6].reshape(3,2)
        b = dtype[1..2]
        assert { a.dot(b) == [5, 11, 17] }
      end
      test "vector.dot(matrix)" do
        a = dtype[1..2]
        b = dtype[1..6].reshape(2,3)
        assert { a.dot(b) == [9, 12, 15] }
      end
      test "matrix.dot(matrix)" do
        a = dtype[1..6].reshape(3,2)
        b = dtype[1..6].reshape(2,3)
        assert { a.dot(b) == [[9, 12, 15], [19, 26, 33], [29, 40, 51]] }
        assert { b.dot(a) == [[22, 28], [49, 64]] }
      end
      test "matrix.dot(matrix) with incorrect shape" do
        a = dtype[1..6].reshape(3,2)
        b = dtype[1..9].reshape(3,3)
        assert_raise(Numo::NArray::ShapeError) { a.dot(b) }
      end
    end

    sub_test_case "#{dtype}, simd" do
      test "no simd add" do
        a = dtype[4..6]
        b = dtype[1..3]
        assert { a + b         == [5, 7, 9] }
        assert { a.inplace + b == [5, 7, 9] }
      end
      test "no simd sub" do
        a = dtype[4..6]
        b = dtype[1..3]
        assert { a - b         == [3, 3, 3] }
        assert { a.inplace - b == [3, 3, 3] }
      end
      test "no simd mul" do
        a = dtype[4..6]
        b = dtype[1..3]
        assert { a * b         == [4, 10, 18] }
        assert { a.inplace * b == [4, 10, 18] }
      end
      test "no simd div" do
        a = dtype[4..6]
        b = dtype[1..3]
        assert { a / b         == [4, 2.5, 2] }
        assert { a.inplace / b == [4, 2.5, 2] }
      end
      test "no simd sqrt" do
        a = dtype[4,9,16]
        assert { Numo::NMath.sqrt(a)         == [2, 3, 4] }
        assert { Numo::NMath.sqrt(a.inplace) == [2, 3, 4] }
      end

      test "simd add" do
        a = dtype[11..19]
        b = dtype.ones(9)
        assert { a + b         == [12, 13, 14, 15, 16, 17, 18, 19, 20] }
        assert { a.inplace + b == [12, 13, 14, 15, 16, 17, 18, 19, 20] }
      end
      test "simd sub" do
        a = dtype[11..19]
        b = dtype.ones(9)
        assert { a - b         == [10, 11, 12, 13, 14, 15, 16, 17, 18] }
        assert { a.inplace - b == [10, 11, 12, 13, 14, 15, 16, 17, 18] }
      end
      test "simd mul" do
        a = dtype[11..19]
        b = dtype.ones(9) * 2
        assert { a * b         == [22, 24, 26, 28, 30, 32, 34, 36, 38] }
        assert { a.inplace * b == [22, 24, 26, 28, 30, 32, 34, 36, 38] }
      end
      test "simd div" do
        a = dtype[11..19]
        b = dtype.ones(9) * 2
        assert { a / b         == [5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5] }
        assert { a.inplace / b == [5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5] }
      end
      test "simd sqrt" do
        a = dtype[4,9,16,25,36,49,64,81,100]
        assert { Numo::NMath.sqrt(a)         == [2, 3, 4, 5, 6, 7, 8, 9, 10] }
        assert { Numo::NMath.sqrt(a.inplace) == [2, 3, 4, 5, 6, 7, 8, 9, 10] }
      end

      test "simd broadcast scalar add" do
        a = dtype[1..9]
        assert { a + 1         == [2, 3, 4, 5, 6, 7, 8, 9, 10] }
        assert { a.inplace + 1 == [2, 3, 4, 5, 6, 7, 8, 9, 10] }
      end

      test "simd broadcast not scalar add" do
        a = dtype[10..19].reshape(2,5)
        b = dtype[10..14]
        assert { a + b         == [[20, 22, 24, 26, 28], [25, 27, 29, 31, 33]] }
        assert { a.inplace + b == [[20, 22, 24, 26, 28], [25, 27, 29, 31, 33]] }
      end

      test "simd view add" do
        a = dtype[10..19][1..9]
        b = dtype[10..19][1..9]
        assert { a + b         == [22, 24, 26, 28, 30, 32, 34, 36, 38] }
        assert { a.inplace + b == [22, 24, 26, 28, 30, 32, 34, 36, 38] }
      end

      test "simd view sqrt" do
        a = dtype[1,4,9,16,25,36,49,64,81,100]
        assert { Numo::NMath.sqrt(a[1..9])         == [2, 3, 4, 5, 6, 7, 8, 9, 10] }
        assert { Numo::NMath.sqrt(a[1..9].inplace) == [2, 3, 4, 5, 6, 7, 8, 9, 10] }
      end
    end
  end
end
