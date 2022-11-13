`timescale 1ps/100fs

module file #(parameter I_SZ=50)  (input [31:0] j, output reg[I_SZ-1:0] ins);
reg[I_SZ-1:0] data[0:9999];
initial begin 
    $readmemh("instructions.txt",data); 
end
integer i;
initial begin
for(i=0;i<j+1;i=i+1)
$display ("%b", data[i]);
end
always @(j) begin
    ins=data[j];
end 
endmodule

module cache_mem;
parameter M=65536;                 //number of words in main memory
parameter B=2;                 // number of words in each block
parameter W=32;                 //number of bits in each word
parameter A=4;                  //associativity / number of ways
parameter N=256;                 //number of sets in cache
parameter I_SZ=50;             //number of bits in the instruction
parameter ADD_SZ=16;           //number of bits in the address
parameter TAG_SZ=7;            //number of bits in the tag;
parameter BLK_OFF_SZ=1;        //number of bits in block offset
parameter IND_SZ=8;            //number of bits in the index size
reg valid[N-1:0][A-1:0];
reg[TAG_SZ-1:0] tags[N-1:0][A-1:0];
reg temp_valid;
reg[TAG_SZ-1:0] temp_tag;
wire[I_SZ-1:0] instruction;
wire[ADD_SZ-1:0] address;
wire[TAG_SZ-1:0] tag;
wire[IND_SZ-1:0] index;
wire[BLK_OFF_SZ-1:0] block_offset;
wire rd;
wire wr;
wire[31:0] counter;
reg[31:0] cnt;
reg[A-1:0] comp;
reg[A-1:0] hit;
reg fn_hit;
reg[W-1:0] read_data;
assign address=instruction[I_SZ-1:I_SZ-ADD_SZ];
assign rd=instruction[1];
assign wr=instruction[0];
assign tag=address[ADD_SZ-1:ADD_SZ-TAG_SZ];
assign index=address[ADD_SZ-TAG_SZ-1:ADD_SZ-TAG_SZ-IND_SZ];
assign block_offset=address[BLK_OFF_SZ-1:0];
assign counter=cnt;
reg clk;
always #10 clk = !clk;
integer hits,miss,tries;
integer pos;
file #(.I_SZ(I_SZ)) f(.j(counter),.ins(instruction));
initial begin
    cnt=32'b0;
    clk=1'b0;
    hits=0;
    miss=0;
    tries=0;
    for(integer i=0;i<N;i++)begin
        for(integer j=0;j<A;j++) begin
            valid[i][j]=1'b0;
            tags[i][j]=$random%65536;
        end
    end
end
always@(posedge clk) begin
    #10;
    cnt=cnt+1;
    tries=tries+1;
    fn_hit=1'b0;
    for(integer i=0;i<A;i=i+1) begin
        if(tags[index][i]==tag) begin
            comp[i]=1'b1;
        end
        else begin
            comp[i]=1'b0;
        end
    end
    for(integer i=0;i<A;i++) begin
        hit[i]=comp[i] & valid[index][i];
        fn_hit=fn_hit | hit[i];
    end
    if(fn_hit) begin
        hits=hits+1;
        for(integer i=0;i<A;i++) begin
            if(hit[i]) begin //i'th way has a hit
                if(rd) begin  // in case of a read signal
                    for(integer j=A-1;j>i;j--) begin
                        if(valid[index][j]) begin
                            temp_tag=tags[index][i];
                            temp_valid=valid[index][i];
                            for(integer k=i;k<j;k++) begin
                                valid[index][k]=valid[index][k+1];
                                tags[index][k]=tags[index][k+1];
                            end
                            valid[index][j]=temp_valid;
                            tags[index][j]=temp_tag;
                        end
                    end
                end
                else if(wr) begin   //in case of write , write back is implemented
                    for(integer j=A-1;j>i;j--) begin
                        if(valid[index][j]) begin
                            temp_tag=tags[index][i];
                            temp_valid=valid[index][i];                     
                            for(integer k=i;k<j;k++) begin
                                valid[index][k]=valid[index][k+1];
                                tags[index][k]=tags[index][k+1];
                            end
                            valid[index][j]=temp_valid;
                            tags[index][j]=temp_tag;
                        end
                    end
                end
            end
        end
    end
    else begin //in case of a miss
        miss=miss+1;
        if(valid[A-1][index]) begin
            for(integer k=1;k<A-1;k++) begin
                valid[index][k]=valid[index][k+1];
                tags[index][k]=tags[index][k+1];
            end
        end
        else begin    //some ways are invalid and hence block must be filled
            for(integer i=0;i<A-1;i++) begin
                if((valid[index][i]) &(valid[index][i+1]==1'b0)) begin   //all the ways upto i are valid
                    pos=i+1;
                end
            end
            valid[index][pos]=1'b1;
            tags[index][pos]=tag;

        end
        if(valid[index][0]==1'b0)  begin
            valid[index][0]=1'b1;
            tags[index][0]=tag;
        end
    end
    if(cnt==41832) begin
        $display("Number of hits = %d",hits);
        $display("Number of misses = %d",miss);
        $display("Total number of tries = %d",tries);
        $display($time);
        $finish;
    end
end
endmodule