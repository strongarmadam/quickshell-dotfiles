import unittest
import datetime as dt
from zoneinfo import ZoneInfo
import bridge
class CalendarTests(unittest.TestCase):
    def event(self, **fields):
        return {'id':'event','uid':'stable','calendar_id':'one','start':'2026-10-26T10:00:00+07:00','end':'2026-10-26T11:00:00+07:00','notifications':[{'type':'notify','trigger':'-PT15M'}],**fields}
    def test_exact_due_and_timezone(self):
        e=self.event(); due=bridge.timestamp(e['start'])-900
        self.assertEqual(bridge.due_reminders([e],due-1,{}),[])
        self.assertEqual(len(bridge.due_reminders([e],due,{})),1)
        self.assertEqual(due+900,bridge.timestamp('2026-10-26T03:00:00Z'))
    def test_dedupe_and_recurring(self):
        e=self.event(); due=bridge.timestamp(e['start'])-900
        key=bridge.due_reminders([e],due,{})[0][0]
        self.assertEqual(bridge.due_reminders([e],due,{key:due}),[])
        e['start']='2026-10-27T10:00:00+07:00'
        self.assertEqual(len(bridge.due_reminders([e],due+86400,{key:due})),1)
    def test_email_and_stale(self):
        e=self.event(); due=bridge.timestamp(e['start'])-900
        self.assertEqual(bridge.due_reminders([e],due+901,{}),[])
        e['notifications'][0]['type']='email'
        self.assertEqual(bridge.due_reminders([e],due,{}),[])
    def test_all_day(self):
        e=self.event(start='2026-10-26T00:00:00Z',all_day=True,notifications=[{'type':'notify','trigger':'-P1D'}])
        due=bridge.timestamp('2026-10-25T00:00:00+07:00')
        self.assertEqual(len(bridge.due_reminders([e],due,{},ZoneInfo('Asia/Bangkok'))),1)
    def test_duration_dst(self):
        self.assertEqual(bridge.duration('-P1DT2H30M'),-95400)
        self.assertEqual(bridge.duration('PT0S'),0)
        self.assertEqual(bridge.timestamp('2026-11-01T01:30:00-05:00')-bridge.timestamp('2026-11-01T01:30:00-04:00'),3600)
    def test_minimal_cache(self):
        e=self.event(attendees=['someone'],conference={'password':'secret'})
        clean=bridge.normalize([e],ZoneInfo('Asia/Bangkok'))[0]
        self.assertNotIn('conference',clean)
        self.assertNotIn('attendees',clean)

class IcsTests(unittest.TestCase):
    ICS = """BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:weekly-1@test
SUMMARY:Team standup
LOCATION:Room 4
DTSTART;TZID=Asia/Bangkok:20261112T093000
DTEND;TZID=Asia/Bangkok:20261112T094500
RRULE:FREQ=WEEKLY;COUNT=5
BEGIN:VALARM
ACTION:DISPLAY
TRIGGER:-PT15M
END:VALARM
END:VEVENT
BEGIN:VEVENT
UID:allday-1@test
SUMMARY:Holiday
DTSTART;VALUE=DATE:20261120
DTEND;VALUE=DATE:20261121
END:VEVENT
END:VCALENDAR
"""
    def parse(self):
        return bridge.parse_ics(self.ICS,'ics0','Google',ZoneInfo('Asia/Bangkok'),
                                dt.date(2026,11,1),dt.date(2026,12,31))
    def test_fields_and_summary(self):
        events={e['start']:e for e in self.parse()}
        first=events['2026-11-12T09:30:00+07:00']
        self.assertEqual(first['summary'],'Team standup')
        self.assertEqual(first['location'],'Room 4')
        self.assertFalse(first['all_day'])
        self.assertTrue(first['recurring'])
        self.assertEqual(first['notifications'],[{'type':'notify','trigger':'-PT15M'}])
    def test_recurrence_count(self):
        self.assertEqual(len([e for e in self.parse() if e['summary']=='Team standup']),5)
    def test_all_day(self):
        holiday=[e for e in self.parse() if e['summary']=='Holiday'][0]
        self.assertTrue(holiday['all_day'])
        self.assertEqual(holiday['start'][:10],'2026-11-20')
    def test_reminder_fires(self):
        now=bridge.timestamp('2026-11-12T09:15:00+07:00')
        due=bridge.due_reminders(bridge.normalize(self.parse(),ZoneInfo('Asia/Bangkok')),now,{})
        self.assertEqual([d[1]['summary'] for d in due],['Team standup'])
    def test_fallback_without_dateutil(self):
        saved=bridge._rrulestr; bridge._rrulestr=None
        try: self.assertEqual(len([e for e in self.parse() if e['summary']=='Team standup']),5)
        finally: bridge._rrulestr=saved
if __name__=='__main__': unittest.main()
