#include "timetablemodel.h"
#include <QLocale>
#include <QTimeZone>
#include <QRegularExpression>
#include <QMap>
#include <algorithm>

// ==================== LessonItem ====================

LessonItem::LessonItem(QObject *parent)
    : QObject(parent)
{
}

LessonItem::LessonItem(const QJsonObject &json, QObject *parent)
    : QObject(parent)
{
    parseJson(json);
}

void LessonItem::parseJson(const QJsonObject &json)
{
    m_id = QString::number(json["id"].toVariant().toLongLong());
    
    // Parse times - API returns Unix timestamps (seconds since epoch)
    qint64 beginsAt = json["begins_at"].toVariant().toLongLong();
    qint64 endsAt = json["ends_at"].toVariant().toLongLong();
    
    if (beginsAt > 0) {
        QDateTime dt = QDateTime::fromSecsSinceEpoch(beginsAt, QTimeZone("Europe/Berlin"));
        m_startTime = dt.time();
        m_date = dt.date();
    }
    if (endsAt > 0) {
        QDateTime dt = QDateTime::fromSecsSinceEpoch(endsAt, QTimeZone("Europe/Berlin"));
        m_endTime = dt.time();
    }
    
    // Parse meta (contains hour number and booking status)
    QJsonObject meta = json["meta"].toObject();
    m_hourNumber = meta["displayname"].toString();
    if (m_hourNumber.isEmpty()) {
        m_hourNumber = meta["shortname"].toString();
    }
    
    // Parse status from meta
    QString canceled = meta["canceled"].toString();
    QString substituted = meta["substituted"].toString();
    
    if (canceled == "true" || canceled == "1") {
        m_status = LessonStatus::Cancelled;
    } else if (substituted == "true" || substituted == "1") {
        m_status = LessonStatus::Substitution;
    }
    
    // Parse course info (subject)
    QJsonObject course = json["course"].toObject();
    if (!course.isEmpty()) {
        QJsonObject courseMeta = course["meta"].toObject();
        m_subject = courseMeta["displayname"].toString();
        if (m_subject.isEmpty()) {
            m_subject = courseMeta["shortname"].toString();
        }
        if (m_subject.isEmpty()) {
            m_subject = course["name"].toString();
        }
        
        // Parse subject for fallback
        QJsonObject subject = course["subject"].toObject();
        if (m_subject.isEmpty() && !subject.isEmpty()) {
            m_subject = subject["shortcut"].toString();
            if (m_subject.isEmpty()) {
                m_subject = subject["name"].toString();
            }
        }
        
        // Parse color - API returns color names like "violet", "orange", etc.
        QString colorStr = courseMeta["color"].toString();
        if (colorStr.isEmpty()) {
            colorStr = subject["color"].toString();
        }
        if (!colorStr.isEmpty()) {
            // Map SDUI color names to hex values
            static const QMap<QString, QString> colorMap = {
                {"violet", "#7C4DFF"},
                {"purple", "#9C27B0"},
                {"blue", "#2196F3"},
                {"lightblue", "#03A9F4"},
                {"cyan", "#00BCD4"},
                {"teal", "#009688"},
                {"green", "#4CAF50"},
                {"lightgreen", "#8BC34A"},
                {"lime", "#CDDC39"},
                {"yellow", "#FFEB3B"},
                {"amber", "#FFC107"},
                {"orange", "#FF9800"},
                {"deeporange", "#FF5722"},
                {"red", "#F44336"},
                {"pink", "#E91E63"},
                {"brown", "#795548"},
                {"grey", "#9E9E9E"},
                {"gray", "#9E9E9E"},
                {"bluegrey", "#607D8B"},
                {"bluegray", "#607D8B"}
            };
            
            QString lowerColor = colorStr.toLower().remove(QRegularExpression("[^a-z]"));
            if (colorMap.contains(lowerColor)) {
                m_color = QColor(colorMap[lowerColor]);
            } else if (colorStr.startsWith("#")) {
                m_color = QColor(colorStr);
            } else {
                // Try as QColor name
                m_color = QColor(colorStr);
            }
        }
    }
    
    // Default color if none set
    if (!m_color.isValid()) {
        m_color = QColor("#FF6B35"); // SDUI Orange
    }
    
    // Parse teachers - API returns direct name/shortcut, not nested meta
    QJsonArray teachers = json["teachers"].toArray();
    if (!teachers.isEmpty()) {
        QJsonObject teacher = teachers[0].toObject();
        m_teacher = teacher["shortcut"].toString();
        if (m_teacher.isEmpty()) {
            m_teacher = teacher["name"].toString();
        }
    }
    
    // Parse bookables (rooms) - API returns direct name/shortcut
    QJsonArray bookables = json["bookables"].toArray();
    if (!bookables.isEmpty()) {
        QJsonObject bookable = bookables[0].toObject();
        m_room = bookable["shortcut"].toString();
        if (m_room.isEmpty()) {
            m_room = bookable["name"].toString();
        }
    }
    
    // Parse substitution info
    QJsonObject substitution = json["substitution"].toObject();
    if (!substitution.isEmpty()) {
        // Original teacher
        QJsonArray origTeachers = substitution["original_teachers"].toArray();
        if (!origTeachers.isEmpty()) {
            QJsonObject origTeacher = origTeachers[0].toObject();
            QJsonObject origMeta = origTeacher["meta"].toObject();
            m_originalTeacher = origMeta["displayname"].toString();
            if (m_originalTeacher.isEmpty()) {
                m_originalTeacher = origMeta["shortname"].toString();
            }
        }
        
        // Original room
        QJsonArray origBookables = substitution["original_bookables"].toArray();
        if (!origBookables.isEmpty()) {
            QJsonObject origBookable = origBookables[0].toObject();
            QJsonObject origMeta = origBookable["meta"].toObject();
            m_originalRoom = origMeta["displayname"].toString();
            if (m_originalRoom.isEmpty()) {
                m_originalRoom = origMeta["shortname"].toString();
            }
        }
        
        // Check for room/teacher changes
        if (!m_originalRoom.isEmpty() && m_originalRoom != m_room) {
            if (m_status == LessonStatus::Normal) {
                m_status = LessonStatus::RoomChanged;
            }
        }
        if (!m_originalTeacher.isEmpty() && m_originalTeacher != m_teacher) {
            if (m_status == LessonStatus::Normal) {
                m_status = LessonStatus::TeacherChanged;
            }
        }
        
        // Comment
        m_comment = substitution["comment"].toString();
    }
}

QString LessonItem::statusText() const
{
    switch (m_status) {
    case LessonStatus::Cancelled:
        return tr("Cancelled");
    case LessonStatus::Substitution:
        return tr("Substitution");
    case LessonStatus::RoomChanged:
        return tr("Room changed");
    case LessonStatus::TeacherChanged:
        return tr("Teacher changed");
    case LessonStatus::Additional:
        return tr("Additional");
    default:
        return "";
    }
}

// ==================== TimetableModel ====================

TimetableModel::TimetableModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_selectedDate = QDate::currentDate();
    m_weekStart = getWeekStart(m_selectedDate);
}

TimetableModel::~TimetableModel()
{
    clear();
}

int TimetableModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_lessons.count();
}

QVariant TimetableModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_lessons.count())
        return QVariant();
    
    const LessonItem *lesson = m_lessons.at(index.row());
    
    switch (role) {
    case IdRole: return lesson->id();
    case SubjectRole: return lesson->subject();
    case TeacherRole: return lesson->teacher();
    case RoomRole: return lesson->room();
    case HourNumberRole: return lesson->hourNumber();
    case StartTimeRole: return lesson->startTime();
    case EndTimeRole: return lesson->endTime();
    case DateRole: return lesson->date();
    case ColorRole: return lesson->color();
    case StatusRole: return lesson->status();
    case StatusTextRole: return lesson->statusText();
    case OriginalTeacherRole: return lesson->originalTeacher();
    case OriginalRoomRole: return lesson->originalRoom();
    case CommentRole: return lesson->comment();
    case DayIndexRole: return m_weekStart.daysTo(lesson->date());
    case RowIndexRole: {
        int idx = m_hourSlots.indexOf(lesson->hourNumber());
        return idx >= 0 ? idx : 0;
    }
    default: return QVariant();
    }
}

QHash<int, QByteArray> TimetableModel::roleNames() const
{
    return {
        {IdRole, "lessonId"},
        {SubjectRole, "subject"},
        {TeacherRole, "teacher"},
        {RoomRole, "room"},
        {HourNumberRole, "hourNumber"},
        {StartTimeRole, "startTime"},
        {EndTimeRole, "endTime"},
        {DateRole, "date"},
        {ColorRole, "lessonColor"},
        {StatusRole, "status"},
        {StatusTextRole, "statusText"},
        {OriginalTeacherRole, "originalTeacher"},
        {OriginalRoomRole, "originalRoom"},
        {CommentRole, "comment"},
        {DayIndexRole, "dayIndex"},
        {RowIndexRole, "rowIndex"}
    };
}

void TimetableModel::setWeekStart(const QDate &date)
{
    QDate newWeekStart = getWeekStart(date);
    if (m_weekStart != newWeekStart) {
        m_weekStart = newWeekStart;
        emit weekStartChanged();
    }
}

void TimetableModel::setViewMode(int mode)
{
    if (m_viewMode != static_cast<ViewMode>(mode)) {
        m_viewMode = static_cast<ViewMode>(mode);
        emit viewModeChanged();
    }
}

void TimetableModel::setSelectedDate(const QDate &date)
{
    if (m_selectedDate != date) {
        m_selectedDate = date;
        m_weekStart = getWeekStart(date);
        emit selectedDateChanged();
        emit weekStartChanged();
    }
}

void TimetableModel::loadFromJson(const QJsonObject &response)
{
    beginResetModel();
    clear();
    
    QJsonObject data = response["data"].toObject();
    QJsonArray lessons = data["lessons"].toArray();
    
    for (const QJsonValue &val : lessons) {
        QJsonObject lessonObj = val.toObject();
        LessonItem *lesson = new LessonItem(lessonObj, this);
        m_lessons.append(lesson);
    }
    
    // Sort by date and time
    std::sort(m_lessons.begin(), m_lessons.end(), [](LessonItem *a, LessonItem *b) {
        if (a->date() != b->date()) return a->date() < b->date();
        return a->startTime() < b->startTime();
    });
    
    buildHourSlots();
    
    endResetModel();
    emit dataChanged();
}

void TimetableModel::clear()
{
    qDeleteAll(m_lessons);
    m_lessons.clear();
    m_hourSlots.clear();
    m_hourTimes.clear();
}

void TimetableModel::buildHourSlots()
{
    m_hourSlots.clear();
    m_hourTimes.clear();
    
    QMap<QString, QPair<QTime, QTime>> hourMap;
    
    for (const LessonItem *lesson : m_lessons) {
        QString hour = lesson->hourNumber();
        if (hour.isEmpty()) {
            hour = lesson->startTime().toString("HH:mm");
        }
        
        if (!hourMap.contains(hour)) {
            hourMap[hour] = qMakePair(lesson->startTime(), lesson->endTime());
        }
    }
    
    // Sort hour slots numerically
    QStringList keys = hourMap.keys();
    std::sort(keys.begin(), keys.end(), [](const QString &a, const QString &b) {
        // Try to extract first number
        QString numA = a.split(QRegularExpression("[^0-9]")).first();
        QString numB = b.split(QRegularExpression("[^0-9]")).first();
        
        bool okA, okB;
        int intA = numA.toInt(&okA);
        int intB = numB.toInt(&okB);
        
        if (okA && okB) return intA < intB;
        return a < b;
    });
    
    m_hourSlots = keys;
    m_hourTimes = hourMap;
}

QVariantList TimetableModel::lessonsForDay(const QDate &date) const
{
    QVariantList result;
    for (LessonItem *lesson : m_lessons) {
        if (lesson->date() == date) {
            result.append(QVariant::fromValue(lesson));
        }
    }
    return result;
}

QVariantList TimetableModel::lessonsForHour(const QDate &date, const QString &hourNumber) const
{
    QVariantList result;
    for (LessonItem *lesson : m_lessons) {
        if (lesson->date() == date && lesson->hourNumber() == hourNumber) {
            result.append(QVariant::fromValue(lesson));
        }
    }
    return result;
}

void TimetableModel::goToToday()
{
    setSelectedDate(QDate::currentDate());
}

void TimetableModel::nextWeek()
{
    setSelectedDate(m_selectedDate.addDays(7));
}

void TimetableModel::previousWeek()
{
    setSelectedDate(m_selectedDate.addDays(-7));
}

void TimetableModel::nextDay()
{
    setSelectedDate(m_selectedDate.addDays(1));
}

void TimetableModel::previousDay()
{
    setSelectedDate(m_selectedDate.addDays(-1));
}

QString TimetableModel::dayName(int dayIndex) const
{
    QDate date = m_weekStart.addDays(dayIndex);
    return QLocale().dayName(date.dayOfWeek(), QLocale::ShortFormat);
}

QDate TimetableModel::dateForDayIndex(int dayIndex) const
{
    return m_weekStart.addDays(dayIndex);
}

bool TimetableModel::isToday(const QDate &date) const
{
    return date == QDate::currentDate();
}

int TimetableModel::daysToShow() const
{
    switch (m_viewMode) {
    case Day: return 1;
    case WorkWeek: return 5;
    case FullWeek: return 7;
    default: return 5;
    }
}

QDate TimetableModel::getWeekStart(const QDate &date) const
{
    // Start week on Monday
    int daysFromMonday = date.dayOfWeek() - 1;
    return date.addDays(-daysFromMonday);
}
