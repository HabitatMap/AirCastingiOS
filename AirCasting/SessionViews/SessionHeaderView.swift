//
//  SessionHeader.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct SessionHeaderView: View {
    let action: () -> Void
    let isExpandButtonNeeded: Bool
    @ObservedObject var session: SessionEntity
    @State private var showModal = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                dateAndTime
                Spacer()
                actionsMenu
            }.sheet(isPresented: $showModal, content: {
                ShareViewModal()
            })
            nameLabelAndExpandButton
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
    }
}

private extension SessionHeaderView {
    var dateAndTime: some View {
        guard let start = session.startTime else {
            return Text("")
        }
        let end = session.endTime ?? Date()
        
        let formatter = DateIntervalFormatter()
        
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        let string = DateIntervalFormatter().string(from: start, to: end)
        return Text(string)
    }
    
    var nameLabelAndExpandButton: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(session.name ?? "")
                    .font(Font.moderate(size: 18, weight: .bold))
                Spacer()
                if isExpandButtonNeeded {
                    Button(action: {
                        action()
                    }) {
                        Image("expandButtonIcon")
                            .renderingMode(.original)
                    }
                }
            }
            Text("\(session.type?.description ?? SessionType.unknown("").description), \(session.deviceType?.description ?? "")")
                .font(Font.moderate(size: 13, weight: .regular))
        }
        .foregroundColor(.darkBlue)
    }

    var actionsMenu: some View {
        Menu {
            Button {
                // action here
            } label: {
                Label("Resume recording", systemImage: "repeat")
            }
            
            Button {
                // action here
            } label: {
                Label("Edit session", systemImage: "pencil")
            }
            
            Button {
                showModal.toggle()
            } label: {
                Label("Share session", systemImage: "square.and.arrow.up")
            }
            
            Button {
                // action here
            } label: {
                Label("Delete session", systemImage: "xmark.circle")
            }
        } label: {
            ZStack(alignment: .trailing) {
                EditButtonView()
                Rectangle()
                    .frame(width: 30, height: 20, alignment: .trailing)
                    .opacity(0.0001)
            }
        }
    }
    
}

#if DEBUG
struct SessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SessionHeaderView(action: {},
                          isExpandButtonNeeded: true,
                          session: SessionEntity.mock)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
}
#endif
