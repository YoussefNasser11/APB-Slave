module apb_master_tb;

  // inputs
  //Ports

  logic  PRESETn;
  logic    PCLK;

  //bridge to master

  logic [8:0]  apb_write_paddr;
  logic [8:0]  apb_read_paddr;
  logic [7:0]  apb_write_data;
  logic  	     READ_WRITE;
  logic        transfer;


  // slave to master
  logic [7:0] PRDATA;
  logic  PREADY;

  // outputs 
  // master to slave
  logic  PSEL1;
  logic  PSEL2;
  logic  PENABLE;
  logic [8:0] PADDR;
  logic  PWRITE;
  logic [7:0] PWDATA;

  // master to bridge
  logic  [7:0] apb_read_data_out;

  apb_master  apb_master_inst (
    .apb_write_paddr(apb_write_paddr),
    .apb_read_paddr(apb_read_paddr),
    .apb_write_data(apb_write_data),
    .PRDATA(PRDATA),
    .PRESETn(PRESETn),
    .PCLK(PCLK),
    .READ_WRITE(READ_WRITE),
    .transfer(transfer),
    .PREADY(PREADY),
    .PSEL1(PSEL1),
    .PSEL2(PSEL2),
    .PENABLE(PENABLE),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),
    .apb_read_data_out(apb_read_data_out)
  );

  always #5  PCLK = ! PCLK ;

  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars;

    fork
      sequence_tb1;
      slave1;
      slave2;
    join_none
    #300;
    $stop;
  end


  task initialization;
  PRESETn = 1 ;
  PCLK    = 0;


  READ_WRITE = 0;
 


  // slave to master
  PRDATA = 0;
  PREADY = 0 ;

  apb_write_paddr = 9'b0_0000_0000; //adds 2
  apb_read_paddr  = 9'b0_0000_0000;
  apb_write_data  = 8'b0000_0000; // data 33
  transfer        = 0;
  endtask

  task reset;
    PRESETn = 0;
    #10;
    PRESETn = 1;
  endtask

  task brigde_slave1;

    apb_write_paddr = 9'b0_0000_0010; //adds 2
    apb_read_paddr  = 9'b0_0000_0010;
    apb_write_data  = 8'b0011_0011;; // data 33

  endtask

  task brigde_slave2;

    apb_write_paddr = 9'b1_0000_0010;
    apb_read_paddr  = 9'b1_0000_0010;
    apb_write_data  = 8'b0000_1111;


  endtask

  task Bridge_write;
    READ_WRITE = 0;
  endtask

  task Bridge_read;
    READ_WRITE = 1;
  endtask

  task slave1;
    reg [7:0] reg_addr1;
    reg [7:0] mem1 [0:63];

      forever begin
	#1;	
	begin
        if(!PRESETn)
          PREADY = 0;
        else
          if(PSEL1 && !PENABLE && !PWRITE)
            begin PREADY = 0; end

        else if(PSEL1 && PENABLE && !PWRITE)
          begin  PREADY = 1;
            reg_addr1 =  PADDR; 
            PRDATA =  mem1[reg_addr1];
          end
        else if(PSEL1 && !PENABLE && PWRITE)
          begin  PREADY = 0; end

        else if(PSEL1 && PENABLE && PWRITE)
          begin  PREADY = 1;
            mem1[PADDR] = PWDATA; end

        else if (PSEL1) PREADY = 0;
      end
    end
  endtask

  task slave2;

    reg [7:0]reg_addr2;
    reg [7:0] mem2 [0:63];
    forever begin
	#1;
      begin
        if(!PRESETn)
          PREADY = 0;
        else
          if(PSEL2 && !PENABLE && !PWRITE)
            begin PREADY = 0; end

        else if(PSEL2 && PENABLE && !PWRITE)
          begin  PREADY = 1;
            reg_addr2 =  PADDR; 
            PRDATA =  mem2[reg_addr2];
          end
        else if(PSEL2 && !PENABLE && PWRITE)
          begin  PREADY = 0; end

        else if(PSEL2 && PENABLE && PWRITE)
          begin  PREADY = #10 1;
            mem2[PADDR] = PWDATA; end

        else if (PSEL2) PREADY = 0;
      end
    end
  endtask

  task sequence_tb1;
    initialization;
    reset;
    transfer = 1;
    Bridge_write;
    brigde_slave1;
    #50;
    Bridge_read;
    brigde_slave1;
  endtask



endmodule