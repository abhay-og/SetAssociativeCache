`timescale 1ps/100fs



//instruction fetch module starts here

module file #(parameter I_SZ=50)  (input [31:0] j, output reg[I_SZ-1:0] ins);
reg[I_SZ-1:0] data[0:9999];
initial begin 
    $readmemb("instructions.txt",data); 
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

//instruction fetch module ends here




//cache module starts here


module cache_mem;


//variables that can be changed for different cases

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

//end of vairables section


//cache memory variables
reg[W-1:0] block[N-1:0][A-1:0][B-1:0]; 
reg valid[N-1:0][A-1:0];
reg[TAG_SZ-1:0] tags[N-1:0][A-1:0];


//main memory variables
reg[W-1:0] main_mem[M-1:0];

//temporoary block to be used
reg temp_valid;
reg[TAG_SZ-1:0] temp_tag;
reg[W-1:0] temp_block[B-1:0];

//temporoary registers for updating memory during miss
reg[TAG_SZ-1:0] temp_tags;
reg[ADD_SZ-1:0] temp_add;
reg[BLK_OFF_SZ-1:0] temp_block_offset;
reg[IND_SZ-1:0] temp_index;


//declaring the required wires
wire[I_SZ-1:0] instruction;
wire[ADD_SZ-1:0] address;
wire[W-1:0] data;
wire[TAG_SZ-1:0] tag;
wire[IND_SZ-1:0] index;
wire[BLK_OFF_SZ-1:0] block_offset;
wire rd;
wire wr;
wire[31:0] counter;
wire f_hit;
reg[31:0] cnt;
reg[A-1:0] comp;
reg[A-1:0] hit;
reg fn_hit;
reg[W-1:0] read_data;

//assigning all the reqd values to the wires
assign address=instruction[I_SZ-1:I_SZ-ADD_SZ];
assign data=instruction[I_SZ-ADD_SZ-1:2];
assign rd=instruction[1];
assign wr=instruction[0];
assign tag=address[ADD_SZ-1:ADD_SZ-TAG_SZ];
assign index=address[ADD_SZ-TAG_SZ-1:ADD_SZ-TAG_SZ-IND_SZ];
assign block_offset=address[BLK_OFF_SZ-1:0];
assign counter=cnt;
assign f_hit = fn_hit;

//clock
reg clk;
always #10 clk = !clk;

//integers used in the report
integer hits,miss,tries;
integer pos;

//instruction fetch module declaration
file #(.I_SZ(I_SZ)) f(.j(counter),.ins(instruction));


//initial section starts here
initial begin


    //initialising clock and counter for instruction fetch
    cnt=32'b0;
    clk=1'b0;


    //initialising hits and misses to be 0
    hits=0;
    miss=0;
    tries=0;


    //initialising main memory with random values
    for(integer i=0;i<M;i=i+1)begin
    main_mem[i]=$random%65536;
    end

    //setting valid bits to 0 and tags to random
    for(integer i=0;i<N;i++)begin
        for(integer j=0;j<A;j++) begin
            valid[i][j]=1'b0;
            tags[i][j]=$random%65536;
        end
    end

    //initialising cache words to random
    for(integer i=0;i<N;i++)begin
        for(integer j=0;j<A;j++) begin
            for(integer k=0;k<B;k++) begin
                block[i][j][k]=$random%65536;
            end
        end
    end

end
//initial section ends here



//always section starts here
always@(posedge clk) begin

    #10;
    cnt=cnt+1;
    tries=tries+1;


    fn_hit=1'b0;

    //checking the tags of the ways in that particular set
    for(integer i=0;i<A;i=i+1) begin
        if(tags[index][i]==tag) begin
            comp[i]=1'b1;
        end
        else begin
            comp[i]=1'b0;
        end
    end

    //AND with valid bits for each way in that particular set
    for(integer i=0;i<A;i++) begin
        hit[i]=comp[i] & valid[index][i];
        fn_hit=fn_hit | hit[i];
    end


    //in case of a hit
    if(f_hit) begin
        miss=miss+1;

        for(integer i=0;i<A;i++) begin

            if(hit[i]) begin //i'th way has a hit

                if(rd) begin  // in case of a read signal

                    read_data=block[index][i][block_offset];

                    for(integer j=A-1;j>i;j--) begin

                        if(valid[index][j]) begin
                            
                            //storing the current block into temp block
                            temp_tag=tags[index][i];
                            temp_valid=valid[index][i];
                            for(integer k=0;k<B;k++) begin
                                temp_block[k]=block[index][i][k];
                            end

                            //shifting the blocks to the left
                            for(integer k=i;k<j;k++) begin
                                for(integer l=0;l<B;l++)begin
                                    block[index][k][l]=block[index][k+1][l];
                                end
                                valid[index][k]=valid[index][k+1];
                                tags[index][k]=tags[index][k+1];
                            end

                            //storing the most recently used block in the rightmost way
                            for(integer k=0;k<B;k++) begin
                                block[index][j][k]=temp_block[k];
                            end
                            valid[index][j]=temp_valid;
                            tags[index][j]=temp_tag;

                        end

                    end

                end

                else if(wr) begin   //in case of write , write back is implemented

                    block[index][i][block_offset]=data;

                    for(integer j=A-1;j>i;j--) begin

                        if(valid[index][j]) begin

                            //storing the current block into temp block
                            temp_tag=tags[index][i];
                            temp_valid=valid[index][i];
                            for(integer k=0;k<B;k++) begin
                                temp_block[k]=block[index][i][k];
                            end

                            //shifting the blocks to the left
                            for(integer k=i;k<j;k++) begin
                                for(integer l=0;l<B;l++)begin
                                    block[index][k][l]=block[index][k+1][l];
                                end
                                valid[index][k]=valid[index][k+1];
                                tags[index][k]=tags[index][k+1];
                            end

                            //storing the most recently used block in the rightmost way
                            for(integer k=0;k<B;k++) begin
                                block[index][j][k]=temp_block[k];
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

        hits=hits+1;
         //updating the contents of the cache into main memory
        for(integer i=0;i<N;i++)begin

            for(integer j=0;j<A;j++) begin
                if(valid[i][j])begin
                    temp_index=i;
                    temp_tags=tags[i][j];
                    for(integer k=0;k<B;k++) begin
                        temp_block_offset=k;
                        temp_add[BLK_OFF_SZ-1:0]=temp_block_offset;
                        temp_add[ADD_SZ-1:ADD_SZ-TAG_SZ]=temp_tags;
                        temp_add[ADD_SZ-TAG_SZ-1:ADD_SZ-TAG_SZ-IND_SZ]=temp_index;
                        main_mem[temp_add]=block[i][j][k];
                    end
                end
            end

        end


        //storing the memory block into the temp block
        for(integer i=0;i<A;i++) begin
            temp_block[i]=main_mem[A*(address/A)+i];
        end

        //all the ways are valid, block must be replaced 
        if(valid[A-1][index]) begin

            for(integer k=1;k<A-1;k++) begin
                for(integer l=0;l<A;l++)begin
                    block[index][k][l]=block[index][k+1][l];
                end
                valid[index][k]=valid[index][k+1];
                tags[index][k]=tags[index][k+1];
            end

            if(rd) begin
                read_data=block[index][A-1][block_offset];
            end

            else if(wr) begin
                block[index][A-1][block_offset]=data;
            end

        end

        else begin    //some ways are invalid and hence block must be filled
            // $display("%d",A-1);
            for(integer i=0;i<A-1;i++) begin
                if((valid[index][i]) &(valid[index][i+1]==1'b0)) begin   //all the ways upto i are valid
                    pos=i+1;
                end
            end

            valid[index][pos]=1'b1;
            tags[index][pos]=tag;
            for(integer k=0;k<B;k++) begin
                block[index][pos][k]=temp_block[k];
            end

            if(rd) begin
                read_data=block[index][pos][block_offset];
            end

            else if(wr) begin
                block[index][pos][block_offset]=data;
            end

        end

        //no ways are valid yet, so fill into the first block
        if(valid[index][0]==1'b0)  begin
            valid[index][0]=1'b1;
            tags[index][0]=tag;
            for(integer k=0;k<B;k++) begin
                block[index][0][k]=temp_block[k];
            end

            if(rd) begin
                read_data=block[index][0][block_offset];
            end

            else if(wr) begin
                block[index][0][block_offset]=data;
            end

        end

    end


    if(cnt==1000) begin
        $display("Number of hits = %d",hits);
        $display("Number of misses = %d",miss);
        $display("Total number of tries = %d",tries);
        $display($time);
        $finish;
    end
end
//always section ends here



endmodule

//cache module ends here