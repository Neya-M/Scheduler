//
//  ContentView.swift
//  Scheduler
//
//  Created by Neya on 6/28/25.
//
//

import SwiftUI
import Combine

struct Item: Identifiable, Equatable, Codable  {
    var id = UUID()
    var colorName: String
    var mins: Double
    var block_name: String
    var length: CGFloat
    var isEditing = false
    var minsString = ""
}

struct DragRelocateDelegate: DropDelegate {
    let item: Item
    @Binding var items: [Item]
    @Binding var draggingItem: Item?

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingItem,
              dragging != item,
              let fromIndex = items.firstIndex(of: dragging),
              let toIndex = items.firstIndex(of: item)
        else { return }

        // Move the dragging item in the array
        withAnimation {
            items.move(fromOffsets: IndexSet(integer: fromIndex),
                       toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }
}

struct ContentView: View {
    @State private var settings = false
    @State private var showBTimes = true
    @State private var showTimes = true
    @State private var showBlockMins = true
    @State private var showBlockName = true
    @State private var editMode = false
    @State private var startTime = 7.5
    @State private var editStart = false
    @State private var endTime = 8.75
    @State private var editEnd = false
    @State private var colors = ["Blue" : Color.blue,
                                 "Green" : Color.green,
                                 "Orange" : Color.orange,
                                 "Red" : Color.red,
                                 "Yellow" : Color.yellow,
                                 "Purple": Color.purple]
    @State private var colorNames = ["Green", "Orange", "Red", "Yellow", "Blue", "Purple"]
    @State private var newBlockName: String = ""
    @State private var newBlockColor: String = "Blue"
    @State private var newBlockMins: Double = 30
    @State private var addingBlock = false
    @State private var items: [Item] = [
        Item(colorName: "Green", mins: 55, block_name: "Example", length: 180),
        Item(colorName: "Red", mins: 5, block_name: "Example", length: 20)
    ]
    private func deleteItems(at offsets: IndexSet) {
        var newItems = items
        newItems.remove(atOffsets: offsets)
        items = newItems
    }
    @State private var isDragging = false
    @State private var draggingItem: Item?
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    settings.toggle()
                }) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderless)
                .padding()
                .sheet(isPresented: $settings) {
                                PopupFormView(
                                    showBTimes: $showBTimes,
                                    showTimes: $showTimes,
                                    showBlockMins: $showBlockMins,
                                    showBlockName: $showBlockName,
                                    editMode: $editMode
                                )
                            }
            }
            // "my schedule"
            Image(systemName: "clock")
                .padding(CGFloat.leastNormalMagnitude)
                .imageScale(.large)
                .foregroundStyle(.tint)
                .onAppear {
                    let defaults = UserDefaults.standard
                    if defaults.data(forKey: "itemsScheduler") == nil {
                        let defaultItems = [
                            Item(colorName: "Green", mins: 55, block_name: "Example", length: 180),
                            Item(colorName: "Red", mins: 5, block_name: "Example", length: 20)
                        ]
                        if let encoded = try? JSONEncoder().encode(defaultItems) {
                            defaults.set(encoded, forKey: "itemsScheduler")
                        }
                    }
                    if let data = defaults.data(forKey: "itemsScheduler"),
                       let savedItems = try? JSONDecoder().decode([Item].self, from: data) {
                        items = savedItems
                    } else {
                        items = [
                            Item(colorName: "Green", mins: 55, block_name: "Example", length: 180),
                            Item(colorName: "Red", mins: 5, block_name: "Example", length: 20)
                        ]
                    }
                    if defaults.object(forKey: "startScheduler") == nil {
                        UserDefaults.standard.set(7.5, forKey: "startScheduler")
                    }
                    if defaults.object(forKey: "endScheduler") == nil {
                        UserDefaults.standard.set(8.5, forKey: "endScheduler")
                    }
                    if defaults.object(forKey: "showMinsScheduler") == nil {
                        UserDefaults.standard.set(true, forKey: "showMinsScheduler")
                    }
                    if defaults.object(forKey: "showNamesScheduler") == nil {
                        UserDefaults.standard.set(true, forKey: "showNamesScheduler")
                    }
                    if defaults.object(forKey: "showBTimesScheduler") == nil {
                        UserDefaults.standard.set(true, forKey: "showBTimesScheduler")
                    }
                    if defaults.object(forKey: "showTimesScheduler") == nil {
                        UserDefaults.standard.set(true, forKey: "showTimesScheduler")
                    }
                    startTime = UserDefaults.standard.double(forKey: "startScheduler")
                    endTime = UserDefaults.standard.double(forKey: "endScheduler")
                    showTimes = UserDefaults.standard.bool(forKey: "showTimesScheduler")
                    showBTimes = UserDefaults.standard.bool(forKey: "showBTimesScheduler")
                    showBlockMins = UserDefaults.standard.bool(forKey: "showMinsScheduler")
                    showBlockName = UserDefaults.standard.bool(forKey: "showNamesScheduler")
                }
            Text("My Schedule")
            Divider()
            let hours = startTime.truncatingRemainder(dividingBy: 12)
            let timeRemainder = hours.truncatingRemainder(dividingBy: 1)
            let startAM = startTime < 12
            let totalMins = items.reduce(0) { $0 + $1.mins }
            if editStart {
                Slider(value: $startTime, in: 0.0...24.0, step: 1.0/12.0)
                    .onChange(of: startTime) {
                            endTime = startTime + Double(totalMins) / 60.0
                        }
            }
            if showTimes {
                HStack {
                    Text("\((Int(hours - timeRemainder) == 0 ? 12 : Int(hours - timeRemainder))):\(String(format: "%02d", Int(round(timeRemainder * 60)))) \(startAM ? "AM" : "PM")")
                    if editMode {
                        Button(action: {
                            if editStart {
                                editStart = false
                                UserDefaults.standard.set(startTime, forKey: "startScheduler")
                            } else {
                                editStart = true
                                editEnd = false
                            }
                        }) {
                            Image(systemName: "pencil")
                                .imageScale(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                    }
                }
            }
            // Schedule blocks
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colors[item.colorName] ?? .purple)
                                    .frame(width: 500, height: item.length)
                                    .onDrag {
                                        self.draggingItem = item
                                        isDragging = true
                                        return NSItemProvider(object: String(describing: item.id) as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: DragRelocateDelegate(item: item, items: $items, draggingItem: $draggingItem))
                                HStack {
                                    VStack {
                                        if item.length < 45 {
                                            if showBlockName || showBlockMins || editMode {
                                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                    .imageScale(.small)
                                                    .onTapGesture {
                                                        items[index].length = 160
                                                        items[index].isEditing = false
                                                    }
                                            }
                                        } else {
                                            VStack {
                                                if item.isEditing {
                                                    TextField("Block Name", text: $items[index].block_name)
                                                        .padding(.vertical, 8)
                                                        .multilineTextAlignment(.center)
                                                        .frame(width: 200, height: 20)
                                                    Slider(value: $items[index].mins, in: 5...360, step: 5){
                                                        let remainder = item.mins.truncatingRemainder(dividingBy: 60)
                                                        Text("\(remainder) mins")
                                                    } minimumValueLabel: {
                                                        Text("5 mins")
                                                    } maximumValueLabel: {
                                                        Text("4 hours")
                                                    }
                                                    .frame(width: 300, height: 20)
                                                    let remainder = item.mins.truncatingRemainder(dividingBy: 60)
                                                    if (item.mins - remainder) / 60 > 1 {
                                                        Text("\(Int((item.mins - remainder) / 60)) hours")
                                                            .font(.caption)
                                                    } else if (item.mins - remainder) / 60 == 1 {
                                                        Text("1 hour")
                                                            .font(.caption)
                                                    }
                                                    Text("\(Int(remainder)) mins")
                                                        .font(.caption)
                                                    Picker("Color", selection: $items[index].colorName){
                                                        ForEach(colorNames, id: \.self) { name in
                                                            Text(name)
                                                        }
                                                    }
                                                    .pickerStyle(.segmented)
                                                    .frame(width: 200, height: 60)
                                                } else {
                                                    if showBlockName {
                                                        Text("\(item.block_name)")
                                                    }
                                                    if showBlockMins {
                                                        let remainder = item.mins.truncatingRemainder(dividingBy: 60)
                                                        if (item.mins - remainder) / 60 > 1 {
                                                            Text("\(Int((item.mins - remainder) / 60)) hours")
                                                                .font(.caption)
                                                        } else if (item.mins - remainder) / 60 == 1 {
                                                            Text("1 hour")
                                                                .font(.caption)
                                                        }
                                                        Text("\(Int(remainder)) mins")
                                                            .font(.caption)
                                                    }
                                                }
                                            }
                                        }
                                        if item.mins < 30 && item.length > item.mins*4 {
                                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                                .padding()
                                                .onTapGesture{
                                                    items[index].length = item.mins*4
                                                }
                                        }
                                    }
                                    if item.length > 45 && editMode {
                                        Button(action: {
                                            if item.isEditing {
                                                items[index].length = item.mins*4
                                                items[index].isEditing = false
                                                if let encoded = try? JSONEncoder().encode(items) {
                                                    UserDefaults.standard.set(encoded, forKey: "itemsScheduler")
                                                }
                                            } else {
                                                items[index].length = max(item.mins*4, 200)
                                                items[index].isEditing = true
                                            }
                                        }) {
                                            Image(systemName: "pencil")
                                                .imageScale(.medium)
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5)
                                    }
                                    if editMode {
                                        Button(action: {
                                            items.remove(at: index)
                                            if let encoded = try? JSONEncoder().encode(items) {
                                                UserDefaults.standard.set(encoded, forKey: "itemsScheduler")
                                            }
                                            
                                        }) {
                                            Image(systemName: "trash")
                                                .imageScale(.small)
                                        }
                                        .foregroundStyle(.white)
                                    }
                                }
                            }
                            if showBTimes {
                                let currMins = (items.prefix(index+1).reduce(0) { $0 + $1.mins }) / 60 + startTime
                                let bhours = currMins.truncatingRemainder(dividingBy: 12)
                                let btimeRemainder = bhours.truncatingRemainder(dividingBy: 1)
                                let breakAM = currMins < 12
                                Text("\((Int(bhours - btimeRemainder) == 0 ? 12 : Int(bhours - btimeRemainder))):\(String(format: "%02d", Int(round(btimeRemainder * 60)))) \(breakAM ? "AM" : "PM")")
                                    .font(.caption)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                    .padding(1)
                }
            }
            Divider()
            let ehours = endTime.truncatingRemainder(dividingBy: 12)
            let etimeRemainder = ehours.truncatingRemainder(dividingBy: 1)
            let endAM = endTime < 12
            if editEnd {
                Slider(value: $endTime, in: 0.0...24.0, step: 1.0/12.0)
                    .onChange(of: endTime) {
                            startTime = endTime + Double(totalMins) / 60.0
                        }
            }
            if showTimes {
                HStack {
                    Text("\((Int(ehours - etimeRemainder) == 0 ? 12 : Int(ehours - etimeRemainder))):\(String(format: "%02d", Int(round(etimeRemainder * 60)))) \(endAM ? "AM" : "PM")")
                    if editMode {
                        Button(action: {
                            if editEnd {
                                editEnd = false
                                UserDefaults.standard.set(endTime, forKey: "endScheduler")
                            } else {
                                editEnd = true
                                editStart = false
                            }
                        }) {
                            Image(systemName: "pencil")
                                .imageScale(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                    }
                }
            }
            // add new block
            if addingBlock {
                VStack {
                    Text("Add new block")
                        .font(.headline)
                    TextField("Block name", text: $newBlockName)
                        .padding()
                    Slider(value: $newBlockMins, in: 5...360, step: 5)
                        .padding()
                    let remainder = newBlockMins.truncatingRemainder(dividingBy: 60)
                    if (newBlockMins - remainder) / 60 > 1 {
                        Text("\(Int((newBlockMins - remainder) / 60)) hours")
                            .font(.caption)
                    } else if (newBlockMins - remainder) / 60 == 1 {
                        Text("1 hour")
                            .font(.caption)
                    }
                    Text("\(Int(remainder)) mins")
                        .font(.caption)
                    Picker("Color", selection: $newBlockColor){
                        ForEach(colorNames, id: \.self) { name in
                            Text(name)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    HStack {
                        Button(action: {
                            addingBlock = false
                            items.append(Item(colorName: newBlockColor, mins: newBlockMins, block_name: newBlockName, length: newBlockMins*4))
                            newBlockName = ""
                            newBlockMins = 30
                            if let encoded = try? JSONEncoder().encode(items) {
                                UserDefaults.standard.set(encoded, forKey: "itemsScheduler")
                            }
                        }) {
                            ZStack {
                                Capsule()
                                    .foregroundStyle(.blue)
                                    .frame(width: 80, height: 40)
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add")
                                }
                            }
                        }
                        .foregroundStyle(.white)
                        .buttonStyle(.borderless)

                        
                        Button(action:{
                            addingBlock = false
                        }) {
                            ZStack {
                                Capsule()
                                    .foregroundStyle(.blue)
                                    .frame(width: 100, height: 40)
                                HStack {
                                    Image(systemName: "xmark")
                                    Text("Cancel")
                                }
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(.borderless)
                    Spacer()
                }
            } else {
                Button(action: {
                    addingBlock = true
                }) {
                    ZStack {
                        Capsule()
                            .foregroundStyle(.blue)
                            .frame(width: 180, height: 40)
                        HStack {
                            Image(systemName: "plus")
                            Text("Add new block")
                        }
                    }
                }
                .foregroundStyle(.white)
                .buttonStyle(.borderless)

            }
        }
        .colorScheme(.dark)
        .background(Color.black.opacity(0.8))
    }
    
}

struct PopupFormView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showBTimes: Bool
    @Binding var showTimes: Bool
    @Binding var showBlockMins: Bool
    @Binding var showBlockName: Bool
    @Binding var editMode: Bool
    var body: some View {
        NavigationView {
                    Form {
                        Toggle("Show time between blocks", isOn: $showBTimes)
                        Toggle("Show wake up and sleep times", isOn: $showTimes)
                        Toggle("Show block lengths", isOn: $showBlockMins)
                        Toggle("Show block names", isOn: $showBlockName)
                        Toggle("Edit Mode", isOn: $editMode)
                    }
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                UserDefaults.standard.set(showTimes, forKey: "showTimesScheduler")
                                UserDefaults.standard.set(showBTimes, forKey: "showBTimesScheduler")
                                UserDefaults.standard.set(showBlockName, forKey: "showNamesScheduler")
                                UserDefaults.standard.set(showBlockMins, forKey: "showMinsScheduler")
                                dismiss()
                            }
                        }
                    }
                }
        .colorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
