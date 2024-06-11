`timescale 1ns/1ns

module apb_master(
  input [8:0]             apb_write_paddr, // Address for write operations
  input [8:0]             apb_read_paddr,  // Address for read operations
  input [7:0]             apb_write_data,  // Data to write
  input [7:0]             PRDATA,          // Data read from slave
  input                   PRESETn,         // Active-low reset
  input                   PCLK,            // Clock signal
  input                   READ_WRITE,      // Read/Write control signal (0: write, 1: read)
  input                   transfer,        // Transfer control signal
  input                   PREADY,          // Slave ready signal

  output                  PSEL1, PSEL2,    // Select signals for slaves
  output reg              PENABLE,         // Enable signal
  output reg [8:0]        PADDR,           // Address signal
  output reg              PWRITE,          // Write control signal
  output reg [7:0]        PWDATA,          // Data to write to slave
  output wire [7:0]       apb_read_data_out // Data read output
); 

  // State definitions
  localparam IDLE = 3'b001, SETUP = 3'b010, ACCESS = 3'b100;

  // State, address, and data registers
  reg [2:0] state, next_state;
  reg [8:0] PADDR_FF;
  reg [7:0] PWDATA_FF;

  // Sequential logic for state and register updates
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      state <= IDLE;
      PADDR_FF  <= 0;
      PWDATA_FF <= 0;
      PADDR     <= 0;
    end else begin
      state <= next_state; 
      PADDR_FF  <= PADDR;
      PWDATA_FF <= PWDATA;
    end
  end

  // Combinational logic for state transitions and output control
  always @(*) begin
    PWRITE = ~READ_WRITE;
    PADDR  = PADDR_FF;
    PWDATA = PWDATA_FF;

    case (state)
      IDLE: begin 
        PENABLE = 0;
        if (!transfer)
          next_state = IDLE;
        else
          next_state = SETUP;
      end

      SETUP: begin
        PENABLE = 0;
        if (READ_WRITE) 
          PADDR = apb_read_paddr;
        else begin
          PADDR = apb_write_paddr;
          PWDATA = apb_write_data;
        end

        if (transfer)
          next_state = ACCESS;
        else
          next_state = IDLE;
      end

      ACCESS: begin        
        PENABLE = 1;
        if (PSEL1 || PSEL2) begin
          if (PREADY) begin
            if (transfer) begin
              if (!READ_WRITE)
                next_state = SETUP; 
              else
                next_state = SETUP;
            end else
              next_state = IDLE;
          end else
            next_state = ACCESS;
        end else
          next_state = IDLE;
      end 

      default: begin
        next_state = IDLE; 
        PENABLE = 0;
      end
    endcase
  end

  // Select signals for slaves based on address
  assign {PSEL1, PSEL2} = ((state != IDLE) ? (PADDR[8] ? {1'b0, 1'b1} : {1'b1, 1'b0}) : 2'd0);
  assign apb_read_data_out = PRDATA;

endmodule
