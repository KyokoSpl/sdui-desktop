#ifndef TIMETABLEMODEL_H
#define TIMETABLEMODEL_H

#include <QObject>
#include <QAbstractListModel>
#include <QDate>
#include <QTime>
#include <QColor>
#include <QJsonObject>
#include <QJsonArray>

// Lesson status enum
class LessonStatus : public QObject
{
    Q_OBJECT
public:
    enum Status {
        Normal,
        Cancelled,
        Substitution,
        RoomChanged,
        TeacherChanged,
        Additional
    };
    Q_ENUM(Status)
};

// Single lesson item
class LessonItem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString subject READ subject CONSTANT)
    Q_PROPERTY(QString teacher READ teacher CONSTANT)
    Q_PROPERTY(QString room READ room CONSTANT)
    Q_PROPERTY(QString hourNumber READ hourNumber CONSTANT)
    Q_PROPERTY(QTime startTime READ startTime CONSTANT)
    Q_PROPERTY(QTime endTime READ endTime CONSTANT)
    Q_PROPERTY(QDate date READ date CONSTANT)
    Q_PROPERTY(QColor color READ color CONSTANT)
    Q_PROPERTY(int status READ status CONSTANT)
    Q_PROPERTY(QString statusText READ statusText CONSTANT)
    Q_PROPERTY(QString originalTeacher READ originalTeacher CONSTANT)
    Q_PROPERTY(QString originalRoom READ originalRoom CONSTANT)
    Q_PROPERTY(QString comment READ comment CONSTANT)

public:
    explicit LessonItem(QObject *parent = nullptr);
    LessonItem(const QJsonObject &json, QObject *parent = nullptr);
    
    QString id() const { return m_id; }
    QString subject() const { return m_subject; }
    QString teacher() const { return m_teacher; }
    QString room() const { return m_room; }
    QString hourNumber() const { return m_hourNumber; }
    QTime startTime() const { return m_startTime; }
    QTime endTime() const { return m_endTime; }
    QDate date() const { return m_date; }
    QColor color() const { return m_color; }
    int status() const { return m_status; }
    QString statusText() const;
    QString originalTeacher() const { return m_originalTeacher; }
    QString originalRoom() const { return m_originalRoom; }
    QString comment() const { return m_comment; }

private:
    void parseJson(const QJsonObject &json);
    
    QString m_id;
    QString m_subject;
    QString m_teacher;
    QString m_room;
    QString m_hourNumber;
    QTime m_startTime;
    QTime m_endTime;
    QDate m_date;
    QColor m_color;
    LessonStatus::Status m_status = LessonStatus::Normal;
    QString m_originalTeacher;
    QString m_originalRoom;
    QString m_comment;
};

// Model for timetable data
class TimetableModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QDate weekStart READ weekStart WRITE setWeekStart NOTIFY weekStartChanged)
    Q_PROPERTY(int viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
    Q_PROPERTY(QDate selectedDate READ selectedDate WRITE setSelectedDate NOTIFY selectedDateChanged)
    Q_PROPERTY(int lessonCount READ lessonCount NOTIFY dataChanged)
    Q_PROPERTY(QStringList hourSlots READ hourSlots NOTIFY dataChanged)

public:
    enum ViewMode {
        Day = 0,
        WorkWeek = 1,
        FullWeek = 2
    };
    Q_ENUM(ViewMode)
    
    enum Roles {
        IdRole = Qt::UserRole + 1,
        SubjectRole,
        TeacherRole,
        RoomRole,
        HourNumberRole,
        StartTimeRole,
        EndTimeRole,
        DateRole,
        ColorRole,
        StatusRole,
        StatusTextRole,
        OriginalTeacherRole,
        OriginalRoomRole,
        CommentRole,
        DayIndexRole,
        RowIndexRole
    };

    explicit TimetableModel(QObject *parent = nullptr);
    ~TimetableModel();

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Properties
    QDate weekStart() const { return m_weekStart; }
    void setWeekStart(const QDate &date);
    
    int viewMode() const { return m_viewMode; }
    void setViewMode(int mode);
    
    QDate selectedDate() const { return m_selectedDate; }
    void setSelectedDate(const QDate &date);
    
    int lessonCount() const { return m_lessons.count(); }
    QStringList hourSlots() const { return m_hourSlots; }

    // Methods
    Q_INVOKABLE void loadFromJson(const QJsonObject &data);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QVariantList lessonsForDay(const QDate &date) const;
    Q_INVOKABLE QVariantList lessonsForHour(const QDate &date, const QString &hourNumber) const;
    Q_INVOKABLE void goToToday();
    Q_INVOKABLE void nextWeek();
    Q_INVOKABLE void previousWeek();
    Q_INVOKABLE void nextDay();
    Q_INVOKABLE void previousDay();
    Q_INVOKABLE QString dayName(int dayIndex) const;
    Q_INVOKABLE QDate dateForDayIndex(int dayIndex) const;
    Q_INVOKABLE bool isToday(const QDate &date) const;
    Q_INVOKABLE int daysToShow() const;

signals:
    void weekStartChanged();
    void viewModeChanged();
    void selectedDateChanged();
    void dataChanged();

private:
    void buildHourSlots();
    QDate getWeekStart(const QDate &date) const;
    
    QList<LessonItem*> m_lessons;
    QDate m_weekStart;
    QDate m_selectedDate;
    ViewMode m_viewMode = WorkWeek;
    QStringList m_hourSlots;
    QMap<QString, QPair<QTime, QTime>> m_hourTimes;
};

#endif // TIMETABLEMODEL_H
