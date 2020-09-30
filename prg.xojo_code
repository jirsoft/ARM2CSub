#tag Module
Protected Module prg
	#tag Method, Flags = &h0
		Function addLabel(l as String) As Boolean
		  if LABELS.HasKey(l) Then
		    'label already exists
		    return False
		    
		  else
		    'OK
		    LABELS.Value(l) = ADR
		    Return True
		    
		  end if
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function assemble(asmRow as String) As UInt32
		  Var r as String = asmRow.TrimLeft
		  Var help as integer = asmRow.IndexOf(";")
		  Var comment as string = ""
		  Var shift as string = ""
		  Var reg as integer
		  
		  if help > -1 then
		    comment = r.Middle(help - 1)
		    r = r.Left(help - 1)
		  end if
		  r  = r. Uppercase.ReplaceAll(Chr(9), " ")
		  
		  Var label as String =""
		  Var hexcode as UInt32 = 0
		  Var inst as string = ""
		  
		  While r.IndexOf("  ") >= 0
		    r = r.ReplaceAll("  ", " ")
		  Wend
		  
		  if r.Left(1) = "." then
		    'label
		    label = r.NthField(" ", 1).Middle(1).Lowercase
		    r = r.Middle(label.Length + 2)
		    if addLabel(label) Then
		      'label converted to address
		      
		    else
		      'label already exists
		      error("Label '" + label+ "' already exists")
		      Return -1
		      
		    end if
		    
		  end if
		  
		  'opcode
		  Var o, g as Integer = -1
		  Var f as string
		  Var cond as integer = -1
		  Var dest, op1, op2, sum as string
		  
		  inst = r.NthField(" ", 1)
		  Var par as string = r.Middle(inst.Length + 1).ReplaceAll(" ", "")
		  
		  for Each f in INS.Keys
		    if inst.BeginsWith(f) then
		      o = INS.Value(f)
		      g = Bitwise.ShiftRight(o, 4)
		      o = o and 15
		      Exit For
		    end if
		  next f
		  
		  if g > -1 Then
		    select case g
		    case 0
		      'data processing
		      hexcode = Bitwise.ShiftLeft(o, 21)
		      if (o >= 8 and o <= 11) then hexcode = hexcode or Bitwise.ShiftLeft(1, 20)  'TST, TEQ, CMP, CMN alwas affects S flag
		      if inst.Length > f.Length then
		        if inst.Middle(3) = "S" then
		          hexcode = hexcode or Bitwise.ShiftLeft(1, 20)
		          cond = getCondCode(inst.Middle(4))
		          
		        else
		          cond = getCondCode(inst.Middle(f.Length))
		        end if
		        
		        if cond < 0 then
		          error("Unknown condition code '" + inst.Middle(f.Length) + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(cond, 28)
		          
		        end if
		        
		      else
		        hexcode = hexcode or Bitwise.ShiftLeft(14, 28)
		        
		      end if
		      
		      if (o < 8) or (o > 11) then
		        dest = par.NthField(",", 1)
		        if dest.Left(1) = "R" then
		          reg = getRegister(dest.Middle(1))
		          if reg < 0 then
		            error("Unknown destination register '" + dest + "'")
		            return UNDEF
		            
		          else
		            hexcode = hexcode or Bitwise.ShiftLeft(reg, 12)
		            
		          end if
		          
		        else
		          error("Unknown destination register '" + dest + "'")
		          return UNDEF
		          
		        end if
		        op1 = par.NthField(",", 2)
		        op2 = par.NthField(",", 3)
		        
		      else
		        op1 = par.NthField(",", 1)
		        op2 = par.NthField(",", 2)
		      end if
		      
		      if op1.Left(1) = "R" then
		        reg = getRegister(op1.Middle(1))
		        if reg < 0 then
		          error("Unknown operand1 '" + op1 + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(reg, 16)
		          
		        end if
		        
		        
		      else
		        error("Unknown operand1 '" + op1 + "'")
		        return UNDEF
		        
		      end if
		      
		      if op2.Left(1) = "#" then
		        'immediate constant
		        hexcode = hexcode or Bitwise.ShiftLeft(1, 25)
		        help = getImmediate(op2.Middle(1).Val)
		        if help < 0 then
		          error("Immediate constant out of range '" + op2 + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode Or help
		          
		        end if
		        
		      elseif op2.Left(1) = "R" then
		        'register
		        shift = par.NthField(",", 4)
		        help = getRegister(op2.Middle(1))
		        if help < 0 then
		          error("Unknown operand2 '" + op2 + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or help
		          
		        end if
		        
		        if shift <> "" then 
		          'shifted register
		          help = 16 * getShifted(shift)
		          if help > 0 then
		            hexcode = hexcode or help
		            
		          else
		            error("Wrong shifted register operation '" + shift + "'")
		            return UNDEF
		          end if
		        end if
		        
		      else
		        error("Unknown operand2 '" + op2 + "'")
		        return UNDEF
		        
		      end if 
		      
		    case 1
		      'multiply
		      hexcode = Bitwise.ShiftLeft(o, 21)
		      hexcode = hexcode or Bitwise.ShiftLeft(&b1001, 4)
		      
		      if inst.Length > f.Length then
		        if inst.Middle(3) = "S" then 
		          hexcode = hexcode or Bitwise.ShiftLeft(1, 20)
		          cond = getCondCode(inst.Middle(4))
		          
		        else
		          cond = getCondCode(inst.Middle(f.Length))
		        end if
		        
		        if cond < 0 then
		          error("Unknown condition code '" + inst.Middle(f.Length) + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(cond, 28)
		          
		        end if
		        
		      else
		        hexcode = hexcode or Bitwise.ShiftLeft(14, 28)
		        
		      end if
		      dest = par.NthField(",", 1)
		      if dest.Left(1) = "R" then
		        reg = getRegister(dest.Middle(1))
		        if reg < 0 then
		          error("Unknown destination register '" + dest + "'")
		          return UNDEF
		          
		        else
		          if reg = 15 then
		            error("MUL/MLA can't use R15 as destination")
		            return UNDEF
		            
		          else
		            if o = 0 then
		              hexcode = hexcode or Bitwise.ShiftLeft(reg, 12)
		            else
		              hexcode = hexcode or Bitwise.ShiftLeft(reg, 16)
		            end if
		            
		          end if
		          
		        end if
		        
		      else
		        error("MUL/MLA needs register as destination")
		        return UNDEF
		        
		      end if
		      
		      op1 = par.NthField(",", 2)
		      if op1 = dest then
		        error("MUL/MLA can't use same registers as destination and operand1")
		        return UNDEF
		        
		      else
		        if op1.Left(1) = "R" then
		          reg = getRegister(op1.Middle(1))
		          if reg < 0 then
		            error("Unknown register as operand1 '" + op1 + "'")
		            return UNDEF
		            
		          else
		            hexcode = hexcode or reg
		            
		          end if
		          
		        else
		          error("MUL/MLA needs register as operand1")
		          return UNDEF
		          
		        end if
		      end if
		      
		      op2 = par.NthField(",", 3)
		      if op2.Left(1) = "R" then
		        reg = getRegister(op2.Middle(1))
		        if reg < 0 then
		          error("Unknown register as operand2 '" + op2 + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(reg, 8)
		          
		        end if
		        
		      else
		        error("MUL/MLA needs register as operand2")
		        return UNDEF
		        
		      end if
		      if o = 1 then 'MLA
		        sum = par.NthField(",", 4)
		        if sum.Left(1) = "R" then
		          reg = getRegister(sum.Middle(1))
		          if reg < 0 then
		            error("Unknown register as sum '" + sum + "'")
		            return UNDEF
		            
		          else
		            hexcode = hexcode or Bitwise.ShiftLeft(reg, 12)
		            
		          end if
		          
		        else
		          error("MUL/MLA needs register as sum")
		          return UNDEF
		          
		        end if
		      end if
		      
		    case 2
		      'single tregister transfer
		      hexcode = Bitwise.ShiftLeft(o, 20)
		      hexcode = hexcode or Bitwise.ShiftLeft(&b01, 26)
		      if inst.Length > 4 then
		        cond = getCondCode(inst.Middle(f.Length))
		        
		        if cond < 0 then
		          error("Unknown condition code '" + inst.Middle(f.Length) + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(cond, 28)
		          
		        end if
		        
		      else
		        hexcode = hexcode or Bitwise.ShiftLeft(14, 28)
		        
		      end if
		      if inst.Length = 4 or inst.Length = 6 then
		        if inst.Right(1) = "B" then
		          hexcode = hexcode or Bitwise.ShiftLeft(1, 22)
		          
		        else
		          error("Wrong suffix (just B allowed) '" + inst + "'")
		          return UNDEF
		          
		        end if
		      end if
		      
		      dest = par.NthField(",", 1)
		      if dest.Left(1) = "R" then
		        reg = getRegister(dest.Middle(1))
		        if reg < 0 then
		          error("Unknown destination register '" + dest + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(reg, 12)
		          
		        end if
		        
		      else
		        error("LDR/STR needs register as destination/source")
		        return UNDEF
		        
		      end if
		      
		      
		      op1 = par.NthField(",", 2)
		      if op1.Right(1) = "]" then 
		        'postindexed addressing mode
		        reg = getRegister(op1.Middle(2, op1.Length - 3))
		        if reg < 0 then
		          error("Unknown base register '" + op1.Middle(2, op1.Length - 3) + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(reg, 16)
		          
		        end if
		        
		        op2 = par.NthField(",", 3)
		        if op2.Length > 0 then
		          if op2.Left(2) = "-R" then
		            hexcode = hexcode or Bitwise.ShiftLeft(1, 25)
		            reg = getRegister(op2.Middle(2))
		            if reg < 0 then
		              error("Unknown register as operand2 '" + op2 + "'")
		              return UNDEF
		              
		            else
		              hexcode = hexcode or reg
		            end if
		            shift = par.NthField(",", 4)
		            if shift.Length > 0 then
		              help = 16 * getShifted(shift)
		              if (help and 16) > 0 then
		                error("Offset shift need to be constant")
		                return UNDEF
		                
		              else
		                hexcode = hexcode or help
		                
		              end if
		            end if
		            
		          elseif op2.Left(1) = "R" then
		            hexcode = hexcode or Bitwise.ShiftLeft(1, 25)
		            hexcode = hexcode or Bitwise.ShiftLeft(1, 23)
		            reg = getRegister(op2.Middle(1))
		            if reg < 0 then
		              error("Unknown register as operand2 '" + op2 + "'")
		              return UNDEF
		              
		            else
		              hexcode = hexcode or reg
		              
		            end if
		            shift = par.NthField(",", 4)
		            if shift.Length > 0 then
		              help = 16 * getShifted(shift)
		              if (help and 16) > 0 then
		                error("Offset shift need to be constant")
		                return UNDEF
		                
		              else
		                hexcode = hexcode or help
		                
		              end if
		            end if
		            
		          elseif op2.Left(1)="#" then
		            'immediate offset
		            help = op2.Middle(1).Val
		            if help > -4096 and help < 4096 then
		              if help < 0 then
		                help = -help
		              else
		                hexcode = hexcode or Bitwise.ShiftLeft(1, 23)
		              end if
		              hexcode = hexcode or help
		              
		            else
		              error("Offset constant too big '" + op2 + "'")
		              return UNDEF
		              
		            end if
		            
		          else
		            error("Offset have to be register or constant '" + op2 + "'")
		            return UNDEF
		          end if
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(1, 23)
		          hexcode = hexcode or Bitwise.ShiftLeft(1, 24) 'false preindex
		        end if
		        
		      else
		        'pre-index
		        hexcode = hexcode or Bitwise.ShiftLeft(1, 24)
		        if par.Right(1) = "!" then
		          'write back
		          hexcode = hexcode or Bitwise.ShiftLeft(1, 21)
		        end if
		        reg = getRegister(op1.Middle(2))
		        if reg < 0 then
		          error("Unknown base register '" + op1.Middle(2, op1.Length - 3) + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(reg, 16)
		          
		        end if
		        op2 = par.NthField(",", 3)
		        if op2.Length > 0 then
		          if op2.Left(2) = "-R" then
		            hexcode = hexcode or Bitwise.ShiftLeft(1, 25)
		            reg = getRegister(op2.Middle(2))
		            if reg < 0 then
		              error("Unknown register as operand2 '" + op2 + "'")
		              return UNDEF
		              
		            else
		              hexcode = hexcode or reg
		            end if
		            shift = par.NthField(",", 4)
		            if shift.Length > 0 then
		              help = 16 * getShifted(shift)
		              if (help and 16) > 0 then
		                error("Offset shift need to be constant")
		                return UNDEF
		                
		              else
		                hexcode = hexcode or help
		                
		              end if
		            end if
		            
		          elseif op2.Left(1) = "R" then
		            hexcode = hexcode or Bitwise.ShiftLeft(1, 25)
		            hexcode = hexcode or Bitwise.ShiftLeft(1, 23)
		            reg = getRegister(op2.Middle(1))
		            if reg < 0 then
		              error("Unknown register as operand2 '" + op2 + "'")
		              return UNDEF
		              
		            else
		              hexcode = hexcode or reg
		              
		            end if
		            shift = par.NthField(",", 4)
		            if shift.Length > 0 then
		              help = 16 * getShifted(shift)
		              if (help and 16) > 0 then
		                error("Offset shift need to be constant")
		                return UNDEF
		                
		              else
		                hexcode = hexcode or help
		                
		              end if
		            end if
		            
		          elseif op2.Left(1)="#" then
		            'immediate offset
		            help = op2.Middle(1).Val
		            if help > -4096 and help < 4096 then
		              if help < 0 then
		                help = -help
		              else
		                hexcode = hexcode or Bitwise.ShiftLeft(1, 23)
		              end if
		              hexcode = hexcode or help
		              
		            else
		              error("Offset constant too big '" + op2 + "'")
		              return UNDEF
		              
		            end if
		            
		          else
		            error("Offset have to be register or constant '" + op2 + "'")
		            return UNDEF
		          end if
		        end if
		      end if
		      
		    case 3
		      'multiple tregister transfer
		      hexcode = hexcode or Bitwise.ShiftLeft(&b100, 25)
		      hexcode = hexcode or Bitwise.ShiftLeft(o, 20)
		      'hexcode = hexcode or Bitwise.ShiftLeft(1, 22) 'load status register
		      if inst.Length = 7 then
		        cond = getCondCode(inst.Middle(5))
		        
		        if cond < 0 then
		          error("Unknown condition code '" + inst.Middle(5) + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(cond, 28)
		          
		        end if
		        
		      else
		        hexcode = hexcode or Bitwise.ShiftLeft(14, 28)
		        
		      end if
		      
		      dest = par.NthField(",", 1)
		      if dest.Left(1) = "R" then
		        if dest.Right(1) = "!" then 
		          'write back
		          hexcode = hexcode or Bitwise.ShiftLeft(1, 21)
		          dest = dest.Middle(1, dest.Length - 2)
		          
		        else
		          dest = dest.Middle(1, dest.Length - 1)
		          
		        end if
		        reg = getRegister(dest)
		        if reg < 0 then
		          error("Unknown base register '" + dest + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(reg, 16)
		          
		        end if
		        
		      else
		        error("LDM/STM needs register as base")
		        return UNDEF
		        
		      end if
		      if inst.Middle(3, 1) <> "D" then
		        hexcode = hexcode or Bitwise.ShiftLeft(1, 23)
		      end if
		      if inst.Middle(4, 1) = "B" then
		        hexcode = hexcode or Bitwise.ShiftLeft(1, 24)
		      end if
		      
		      help = par.IndexOf("{")
		      if help > 0 then
		        op1 = par.Middle(help)
		        if op1.Right(1) = "}" then
		          op1 = op1.Middle(1, op1.Length - 2)
		          help = 0
		          while op1.Length > 0 
		            op2 = op1.NthField(",", 1)
		            help = getRegs(op2)
		            if help > 0 then
		              hexcode = hexcode or help
		              
		            else
		              error("Register list wrong '" + op2 + "'")
		              return UNDEF
		              
		            end if
		            op1 = op1.Middle(op2.Length + 1)
		          wend
		          
		        else
		          error("Register list not closed '" + op1 + "'")
		          return UNDEF
		          
		        end if
		        
		      else
		        error("LDM/STM needs register list")
		        return UNDEF
		        
		      end if
		      
		    case 4
		      'branch
		      hexcode = hexcode or Bitwise.ShiftLeft(&b101, 25)
		      if inst.Middle(1) = "L" then
		        hexcode = hexcode or Bitwise.ShiftLeft(1, 24)
		      end if
		      if inst.Length > 2 then
		        cond = getCondCode(inst.Middle(inst.Length - 2))
		        
		        if cond < 0 then
		          error("Unknown condition code '" + inst.Middle(inst.Length - 2) + "'")
		          return UNDEF
		          
		        else
		          hexcode = hexcode or Bitwise.ShiftLeft(cond, 28)
		          
		        end if
		        
		      else
		        hexcode = hexcode or Bitwise.ShiftLeft(14, 28)
		        
		      end if
		      
		      help = labelToAdr(par)
		      if help < 0 then
		        error("Unknown label '" + par + "'")
		        return UNDEF
		        
		      else
		        help = (ADR - help) \ 4
		        help = ((help Xor &hffffff) - 1) 
		        hexcode = hexcode or help
		      end if
		      
		    case 5
		      'SWI
		      
		    case 7
		      'pseudo
		      
		    end select
		    
		  else
		    'unknown opcode
		    error("Unknown instruction '" + inst + "'")
		    return UNDEF
		  end if
		  
		  'OK
		  wAsm.out.AddRow(ADR.ToHex(8), formatHexcode(hexcode), label, inst + " " + nicePar(par), comment)
		  wHex.tHex.AddText(formatHexcode(hexcode) + " ")
		  ADR = ADR + 4
		  return hexcode
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub error(e as string)
		  wAsm.out.AddRow("", "", "", "ERROR: ", e)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function formatHexcode(h as UInt32) As string
		  Var a, b, c, d as integer
		  a = h and &hff
		  b = (h and &hff00) \ &h100
		  c = (h and &hff0000) \ &h10000
		  d = (h and &hff000000) \ &h1000000
		  
		  return a.ToHex(2) + " " + b.ToHex(2) + " " + c.ToHex(2) + " " + d.ToHex(2)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getCondCode(cc as string) As integer
		  Static condCodes() as string = Array("EQ", "NE", "CS", "CC", "MI", "PL", "VS", "VC", "HI", "LS", "GE", "LT", "GT", "LE", "AL", "NV")
		  
		  for i as integer = 0 to condCodes.LastRowIndex
		    if cc.Uppercase = condCodes(i) then
		      Return i
		    end if
		  next i
		  return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getImmediate(im as Integer) As integer
		  var e as UInt32 = im and UNDEF
		  Var a, b, c, d, t as UInt32 = e
		  
		  for i as integer = 0 to 15
		    if BitAnd(t, 255) = t then
		      'ok
		      return t + Bitwise.ShiftLeft(i, 8, 32)
		      
		    end if
		    a = BitAnd(t, &hc0000000)
		    b = ShiftRight(a, 30, 32)
		    c = ShiftLeft(t, 2, 32)
		    d = BitAnd(c, UNDEF)
		    
		    t = BitOr(b, d)
		  next i
		  
		  'impossible to create immediate constant
		  return -1
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getRegister(s as string) As integer
		  Var r as integer = s.Val
		  if r < 0 or r > 15 then
		    return -1
		    
		  else
		    return r
		    
		  end if
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getRegs(s as string) As UInt32
		  Var r1, r2 as integer
		  Var rl, rh as string
		  Var r as integer = 0
		  if s.IndexOf("-") > 0 then
		    rl = s.NthField("-", 1)
		    rh = s.NthField("-", 2)
		    if rl.Left(1) = "R" then
		      r1 = rl.Middle(1).Val
		      if r1 >= 0 and r1 <=15 then
		        if rh.Left(1) = "R" then
		          r2 = rh.Middle(1).Val
		          if r2 >= 0 and r2 <=15 then
		            for i as integer = r1 to r2
		              r = r or Bitwise.ShiftLeft(1, i)
		            next i
		            return r
		            
		          else
		            return -1
		            
		          end if
		          
		        else
		          return -1
		          
		        end if
		        
		      else
		        return -1
		        
		      end if
		      
		    else
		      return -1
		      
		    end if
		  else
		    if s.Left(1) = "R" then
		      r1 = s.Middle(1).Val
		      if r1 >=0 and r1 <=15 then
		        r = Bitwise.ShiftLeft(1, r1)
		        return r
		        
		      else
		        return -1
		        
		      end if
		    end if
		  end if
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getShifted(s as string) As Integer
		  if s = "RRX" then
		    return 6
		    
		  elseif s.BeginsWith("LSL#") or s.BeginsWith("ASL#") then
		    if s.Length > 4 then
		      return s.Middle(4).Val * 8
		      
		    else
		      return -1
		      
		    end if
		    
		  elseif s.BeginsWith("LSLR") or s.BeginsWith("ASLR") then
		    if s.Length > 4 then
		      Var r as Integer = getRegister(s.Middle(4))
		      if r < 0 then
		        return -1
		        
		      else
		        return 1 + 16 * r
		        
		      end if
		      
		    else
		      return -1
		      
		    end if
		    
		  elseif  s.BeginsWith("LSR#") then
		    if s.Length > 4 then
		      return 2 + s.Middle(4).Val * 8
		      
		    else
		      return -1
		      
		    end if
		    
		  elseif  s.BeginsWith("LSRR") then
		    if s.Length > 4 then
		      Var r as Integer = getRegister(s.Middle(4))
		      if r < 0 then
		        return -1
		        
		      else
		        return 3 + 16 * r
		        
		      end if
		      
		      
		    else
		      return -1
		      
		    end if
		    
		  elseif s.BeginsWith("ASR#") then
		    if s.Length > 4 then
		      return 4 + s.Middle(4).Val * 8
		      
		    else
		      return -1
		      
		    end if
		    
		  elseif s.BeginsWith("ASRR") then
		    if s.Length > 4 then
		      Var r as Integer = getRegister(s.Middle(4))
		      if r < 0 then
		        return -1
		        
		      else
		        return 5 + 16 * r
		        
		      end if
		      
		      
		    else
		      return -1
		      
		    end if
		    
		  elseif  s.BeginsWith("ROR#") then
		    if s.Length > 4 then
		      return 6 + s.Middle(4).Val * 8
		      
		    else
		      return -1
		      
		    end if
		    
		  elseif  s.BeginsWith("RORR") then
		    if s.Length > 4 then
		      Var r as Integer = getRegister(s.Middle(4))
		      if r < 0 then
		        return -1
		        
		      else
		        return 7 + 16 * r
		        
		      end if
		      
		      
		    else
		      return -1
		      
		    end if
		    
		  else
		    return -1
		    
		  end if
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub init()
		  INS = New Dictionary
		  LABELS = New Dictionary
		  
		  'Data Processing, group 000
		  INS.Value("AND") = &b0000000
		  INS.Value("EOR") = &b0000001
		  INS.Value("SUB") = &b0000010
		  INS.Value("RSB") = &b0000011
		  INS.Value("ADD") = &b0000100
		  INS.Value("ADC") = &b0000101
		  INS.Value("SBC") = &b0000110
		  INS.Value("RSC") = &b0000111
		  INS.Value("TST") = &b0001000
		  INS.Value("TEQ") = &b0001001
		  INS.Value("CMP") = &b0001010
		  INS.Value("CMN") = &b0001011
		  INS.Value("ORR") = &b0001100
		  INS.Value("MOV") = &b0001101
		  INS.Value("BIC") = &b0001110
		  INS.Value("MVN") = &b0001111
		  
		  'Multiply, group 001
		  INS.Value("MUL") = &b0010000
		  INS.Value("MLA") = &b0010001
		  
		  'Single Register Transfer, group 010
		  INS.Value("STR") = &b0100000
		  INS.Value("LDR") = &b0100001
		  
		  'Multiple Register Transfer, group 011
		  INS.Value("STM") = &b0110000
		  INS.Value("LDM") = &b0110001
		  
		  'Branch, group 100
		  INS.Value("B") = &b1000000
		  
		  'SWI, group 101
		  INS.Value("SWI") = &b1010000
		  
		  
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function labelToAdr(l as string) As UInt32
		  if LABELS.HasKey(l) then
		    Return LABELS.Value(l)
		    
		  else
		    return -1
		    
		  end if
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function nicePar(p as string) As string
		  Var n as String = p.ReplaceAll(",", ", ")
		  n = n.ReplaceAll("#", " #")
		  n = n.Replace("LSLR", "LSL R")
		  n = n.Replace("ASLR", "ASL R")
		  n = n.Replace("LSRR", "LSR R")
		  n = n.Replace("ASRR", "ASR R")
		  n = n.Replace("RORR", "ROR R")
		  
		  n = n.ReplaceAll("R01", "R1")
		  n = n.ReplaceAll("R02", "R2")
		  n = n.ReplaceAll("R03", "R3")
		  n = n.ReplaceAll("R04", "R4")
		  n = n.ReplaceAll("R05", "R5")
		  n = n.ReplaceAll("R06", "R6")
		  n = n.ReplaceAll("R07", "R7")
		  n = n.ReplaceAll("R08", "R8")
		  n = n.ReplaceAll("R09", "R9")
		  return n
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ok(s as string)
		  wAsm.out.AddRow("", "", "", s, "")
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		ADR As UInt32 = 0
	#tag EndProperty

	#tag Property, Flags = &h0
		INS As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		LABELS As Dictionary
	#tag EndProperty


	#tag Constant, Name = UNDEF, Type = Double, Dynamic = False, Default = \"&hFFFFFFFF", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="ADR"
			Visible=false
			Group="Behavior"
			InitialValue="0"
			Type="UInt32"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Module
#tag EndModule
