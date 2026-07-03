# Export assembly and decompiled code from Ghidra
# @category Decompilation
# @author Antigravity
# @keybinding
# @menupath
# @toolbar

import os
import java.lang.System
from ghidra.app.decompiler import DecompInterface
from ghidra.util.task import ConsoleTaskMonitor

def run():
    out_dir = "C:\\Users\\jo\\.gemini\\antigravity\\scratch\\kok3-decomp\\ref"
    pseudocode_dir = os.path.join(out_dir, "pseudocode")
    assembly_dir = os.path.join(out_dir, "assembly")
    
    for d in [pseudocode_dir, assembly_dir]:
        if not os.path.exists(d):
            os.makedirs(d)
            
    fm = currentProgram.getFunctionManager()
    funcs = fm.getFunctions(True)
    
    print("Beginning batch export of functions...")
    count = 0
    
    decomp = DecompInterface()
    decomp.openProgram(currentProgram)
    
    for f in funcs:
        if f.isThunk():
            continue
            
        name = f.getName()
        addr = f.getEntryPoint()
        
        class_name = "global"
        parent = f.getParentNamespace()
        if parent and parent.getName() != "global":
            class_name = parent.getName()
            
        file_base = class_name.lower()
        
        # Decompile function logic
        results = decomp.decompileFunction(f, 30, ConsoleTaskMonitor())
        pseudocode = ""
        if results and results.decompileCompleted():
            ccode = results.getDecompiledFunction()
            if ccode:
                pseudocode = ccode.getC()
                
        # Get raw assembly listing
        assembly = []
        listing = currentProgram.getListing()
        code_units = listing.getCodeUnits(f.getBody())
        while code_units.hasNext():
            cu = code_units.next()
            assembly.append("0x{} : {}".format(cu.getAddress(), cu.toString()))
            
        # Append decompiled code to corresponding file
        p_file = os.path.join(pseudocode_dir, "{}.c".format(file_base))
        with open(p_file, "a") as pf:
            pf.write("// Function: {}\n// Address: 0x{}\n".format(name, addr))
            pf.write(pseudocode)
            pf.write("\n\n")
            
        # Append assembly list to corresponding file
        a_file = os.path.join(assembly_dir, "{}.asm".format(file_base))
        with open(a_file, "a") as af:
            af.write("; Function: {}\n; Address: 0x{}\n".format(name, addr))
            af.write("\n".join(assembly))
            af.write("\n\n")
            
        count += 1
        if count % 100 == 0:
            print("Exported {} functions...".format(count))
            decomp.dispose()
            java.lang.System.gc()
            decomp = DecompInterface()
            decomp.openProgram(currentProgram)
            
    decomp.dispose()
    print("Completed! Exported {} functions to {}.".format(count, out_dir))

run()
