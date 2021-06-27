//
//  GameView.swift
//  4Blocks
//
//  Created by forloops on 6/25/21.
//

// Basic falling block game, similar to Tetris.
// (Note to students in the iOS class: even older games
// are usually trademarked, so you can't use the same name.
// Only the patents expire after 20 years).

// When running use the up/down arrows to rotate the falling piece,
// and the spacebar to drop the it immediately.

import Cocoa

class GameView: NSView {
    var blocks = [Int](repeating: -1, count: 150) // piece color num, or -1 if empty
    let pieces: [[[Int]]] = [
        [[0,-2],[0,-1],[0,0],[0,1]],
        [[-1,-1],[-1,0],[0,-1],[0,0]],
        [[-1,-1],[0,-1],[0,0],[1,0]],
        [[0,-1],[1,-1],[-1,0],[0,0]],
        [[-1,-1],[-1,0],[0,0],[1,0]],
    ]
    var currentPiece = 0
    var pieceX = 5
    var pieceY = 13
    var rotation = 0 // increasing rotates clockwise
    
    func fillRect(_ x: Double, _ y: Double, _ width: Double, _ height: Double) {
        let p = NSBezierPath.init(rect: NSRect.init(x: x, y: y, width: width, height: height))
        p.fill()
    }
    
    func setColor(_ red: Double, _ green: Double, _ blue: Double) {
        let c = NSColor.init(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
        c.set()
    }
    
    // Gets one of the four blocks of the current piece,
    // and adjusts it for the current position and rotation.
    func currentPieceBlock(blockNum: Int) -> (Int, Int) {
        let piece = pieces[currentPiece]
        let pieceBlock = piece[blockNum]
        var blockX = pieceBlock[0]
        var blockY = pieceBlock[1]
        switch rotation % 4 {
        case 1:
            (blockX, blockY) = (blockY, -blockX)
        case 2:
            (blockX, blockY) = (-blockX, -blockY)
        case 3:
            (blockX, blockY) = (-blockY, blockX)
        default:
            break
        }
        return (blockX+pieceX, blockY+pieceY)
    }
    
    func drawPiece(colorNum: Int) {
        for i in 0...3 {
            let (x, y) = currentPieceBlock(blockNum: i)
            blocks[y*10+x] = colorNum
        }
    }
    
    func pieceOverlaps() -> Bool {
        for i in 0...3 {
            let (blockX, blockY) = currentPieceBlock(blockNum: i)
            
            // check if piece block goes off the game board
            if blockX < 0 || blockX >= 10 || blockY < 0 || blockY >= 15 {
                return true
            }
            
            // check if there is already a block under piece block
            if blocks[blockY*10+blockX] != -1 {
                return true
            }
        }
        return false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // write falling piece into game blocks
        drawPiece(colorNum: currentPiece)
        
        var blockNum = 0
        var y = 0.0
        while y < 480 {
            var x = 0.0
            
            while x < 320 {
                let blockColor = blocks[blockNum]
                
                switch blockColor {
                case -1:
                    let red = y / 480
                    setColor(red, 1-red, 1)
                case 0:
                    setColor(1,0,0)
                case 1:
                    setColor(0,0,1)
                case 2:
                    setColor(1,0.5,0)
                case 3:
                    setColor(0,1,0)
                case 4:
                    setColor(1,1,0)
                default:
                    setColor(0,0,0)
                }
                
                fillRect(x, y, 32, 32)
                blockNum += 1
                
                x += 32
            }
            
            y += 32
        }
        
        // clear falling piece from game blocks
        drawPiece(colorNum: -1)
    }
        
    func advanceFrame() -> Bool { // returns true if placed piece
        print("advance frame")
        pieceY -= 1
        if pieceOverlaps() {
            pieceY += 1 // move it back
            drawPiece(colorNum: currentPiece) // write it into game board
            
            removeCompleteRows()
            
            // start a new piece
            pieceX = 5
            pieceY = 13
            rotation = 0
            currentPiece = Int.random(in: 0...pieces.count-1)
            return true
        }
        return false
    }
    
    override func keyDown(with event: NSEvent) {
        // I got these numbers by adding a print statement and testing keys
        switch event.keyCode {
        case 123: // left
            print("left")
            pieceX -= 1
            if pieceOverlaps() {
                pieceX += 1
            }
        case 124: // right
            print("right")
            pieceX += 1
            if pieceOverlaps() {
                pieceX -= 1
            }
        case 125: // down
            print("down")
            rotation -= 1
            if pieceOverlaps() {
                rotation += 1
            }
        case 126: // up
            print("up")
            rotation += 1
            if pieceOverlaps() {
                rotation -= 1
            }
        case 49: // space
            while !advanceFrame() {}
            resetTimer()
        default:
            print("key code", event.keyCode)
        }
        setNeedsDisplay(self.bounds)
    }
    
    func removeCompleteRows() {
        // We delete rows by copying the rows from above into the rows below.
        // The row from above may be 1 to 4 rows up depending on how many rows we are deleting.
        // To start off, we are deleting 0 rows so we just copy the row to itself (which does nothing).
        // Each time we find a row to delete we increment this variable,
        // causing us to copy the current row to a row further down.
        var lineToMoveTo = 0
        
        var y = 0
        while y < 15 {
            var lineComplete = true
            for x in 0...9 {
                if blocks[y*10+x] == -1 {
                    lineComplete = false
                    break
                }
            }
            if lineComplete {
                // increment the current line without incrementing lineToMoveTo,
                // which will cause us to copy over the current line with a line
                // from above the next time through the loop
                y += 1
                continue
            }
            // now we copy the row to a lower row
            // (or keep it the same if we haven't deleted rows and so lineToMoveTo == y)
            for x in 0...9 {
                blocks[lineToMoveTo*10+x] = blocks[y*10+x]
            }
            y += 1
            lineToMoveTo += 1
        }
        while lineToMoveTo < 15 {
            // If we deleted a bunch of rows, we will have rows left over at the top
            // that don't have any rows above them to copy over them (for example, we
            // are moving the rows down 2 blocks, but we don't have a row to copy over
            // the top row because 2 blocks up is off the screen).
            // We'll pretend there are clear rows above the screen, and just copy
            // clear blocks into those rows.
            for x in 0...9 {
                blocks[lineToMoveTo*10+x] = -1
            }
            lineToMoveTo += 1
        }
    }
    
    var timer: Timer?
    override func awakeFromNib() {
        // this is called by the system when our app launches
        print("awake from nib called on app launch")
        resetTimer()
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval.init(1.0), repeats: true) { timer in
            // this code runs every 1 second (can change using the number in TimeInterval.init above)
            print("timer fired")
            _ = self.advanceFrame()
            self.setNeedsDisplay(self.bounds) // tells system to call our draw() function
        }
    }
    
    // tell the system we can receive key events
    override var acceptsFirstResponder: Bool { return true }
}
