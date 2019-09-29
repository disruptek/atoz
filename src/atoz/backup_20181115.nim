
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Backup
## version: 2018-11-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Backup</fullname> <p>AWS Backup is a unified backup service designed to protect AWS services and their associated data. AWS Backup simplifies the creation, migration, restoration, and deletion of backups, while also providing reporting and auditing.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/backup/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "backup.ap-northeast-1.amazonaws.com", "ap-southeast-1": "backup.ap-southeast-1.amazonaws.com",
                           "us-west-2": "backup.us-west-2.amazonaws.com",
                           "eu-west-2": "backup.eu-west-2.amazonaws.com", "ap-northeast-3": "backup.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "backup.eu-central-1.amazonaws.com",
                           "us-east-2": "backup.us-east-2.amazonaws.com",
                           "us-east-1": "backup.us-east-1.amazonaws.com", "cn-northwest-1": "backup.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "backup.ap-south-1.amazonaws.com",
                           "eu-north-1": "backup.eu-north-1.amazonaws.com", "ap-northeast-2": "backup.ap-northeast-2.amazonaws.com",
                           "us-west-1": "backup.us-west-1.amazonaws.com", "us-gov-east-1": "backup.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "backup.eu-west-3.amazonaws.com",
                           "cn-north-1": "backup.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "backup.sa-east-1.amazonaws.com",
                           "eu-west-1": "backup.eu-west-1.amazonaws.com", "us-gov-west-1": "backup.us-gov-west-1.amazonaws.com", "ap-southeast-2": "backup.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "backup.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "backup.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "backup.ap-southeast-1.amazonaws.com",
      "us-west-2": "backup.us-west-2.amazonaws.com",
      "eu-west-2": "backup.eu-west-2.amazonaws.com",
      "ap-northeast-3": "backup.ap-northeast-3.amazonaws.com",
      "eu-central-1": "backup.eu-central-1.amazonaws.com",
      "us-east-2": "backup.us-east-2.amazonaws.com",
      "us-east-1": "backup.us-east-1.amazonaws.com",
      "cn-northwest-1": "backup.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "backup.ap-south-1.amazonaws.com",
      "eu-north-1": "backup.eu-north-1.amazonaws.com",
      "ap-northeast-2": "backup.ap-northeast-2.amazonaws.com",
      "us-west-1": "backup.us-west-1.amazonaws.com",
      "us-gov-east-1": "backup.us-gov-east-1.amazonaws.com",
      "eu-west-3": "backup.eu-west-3.amazonaws.com",
      "cn-north-1": "backup.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "backup.sa-east-1.amazonaws.com",
      "eu-west-1": "backup.eu-west-1.amazonaws.com",
      "us-gov-west-1": "backup.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "backup.ap-southeast-2.amazonaws.com",
      "ca-central-1": "backup.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "backup"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateBackupPlan_594034 = ref object of OpenApiRestCall_593437
proc url_CreateBackupPlan_594036(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBackupPlan_594035(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, the existing <code>backupPlanId</code> is returned.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594037 = header.getOrDefault("X-Amz-Date")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Date", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Security-Token")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Security-Token", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Content-Sha256", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Algorithm")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Algorithm", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Signature")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Signature", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-SignedHeaders", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Credential")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Credential", valid_594043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594045: Call_CreateBackupPlan_594034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, the existing <code>backupPlanId</code> is returned.</p>
  ## 
  let valid = call_594045.validator(path, query, header, formData, body)
  let scheme = call_594045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594045.url(scheme.get, call_594045.host, call_594045.base,
                         call_594045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594045, url, valid)

proc call*(call_594046: Call_CreateBackupPlan_594034; body: JsonNode): Recallable =
  ## createBackupPlan
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, the existing <code>backupPlanId</code> is returned.</p>
  ##   body: JObject (required)
  var body_594047 = newJObject()
  if body != nil:
    body_594047 = body
  result = call_594046.call(nil, nil, nil, nil, body_594047)

var createBackupPlan* = Call_CreateBackupPlan_594034(name: "createBackupPlan",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_CreateBackupPlan_594035, base: "/",
    url: url_CreateBackupPlan_594036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlans_593774 = ref object of OpenApiRestCall_593437
proc url_ListBackupPlans_593776(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBackupPlans_593775(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   includeDeleted: JBool
  ##                 : A Boolean value with a default value of <code>FALSE</code> that returns deleted backup plans when set to <code>TRUE</code>.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593888 = query.getOrDefault("NextToken")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "NextToken", valid_593888
  var valid_593889 = query.getOrDefault("maxResults")
  valid_593889 = validateParameter(valid_593889, JInt, required = false, default = nil)
  if valid_593889 != nil:
    section.add "maxResults", valid_593889
  var valid_593890 = query.getOrDefault("nextToken")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "nextToken", valid_593890
  var valid_593891 = query.getOrDefault("includeDeleted")
  valid_593891 = validateParameter(valid_593891, JBool, required = false, default = nil)
  if valid_593891 != nil:
    section.add "includeDeleted", valid_593891
  var valid_593892 = query.getOrDefault("MaxResults")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "MaxResults", valid_593892
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593893 = header.getOrDefault("X-Amz-Date")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Date", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Security-Token")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Security-Token", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Content-Sha256", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-Algorithm")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Algorithm", valid_593896
  var valid_593897 = header.getOrDefault("X-Amz-Signature")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "X-Amz-Signature", valid_593897
  var valid_593898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593898 = validateParameter(valid_593898, JString, required = false,
                                 default = nil)
  if valid_593898 != nil:
    section.add "X-Amz-SignedHeaders", valid_593898
  var valid_593899 = header.getOrDefault("X-Amz-Credential")
  valid_593899 = validateParameter(valid_593899, JString, required = false,
                                 default = nil)
  if valid_593899 != nil:
    section.add "X-Amz-Credential", valid_593899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593922: Call_ListBackupPlans_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ## 
  let valid = call_593922.validator(path, query, header, formData, body)
  let scheme = call_593922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593922.url(scheme.get, call_593922.host, call_593922.base,
                         call_593922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593922, url, valid)

proc call*(call_593993: Call_ListBackupPlans_593774; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; includeDeleted: bool = false;
          MaxResults: string = ""): Recallable =
  ## listBackupPlans
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   includeDeleted: bool
  ##                 : A Boolean value with a default value of <code>FALSE</code> that returns deleted backup plans when set to <code>TRUE</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_593994 = newJObject()
  add(query_593994, "NextToken", newJString(NextToken))
  add(query_593994, "maxResults", newJInt(maxResults))
  add(query_593994, "nextToken", newJString(nextToken))
  add(query_593994, "includeDeleted", newJBool(includeDeleted))
  add(query_593994, "MaxResults", newJString(MaxResults))
  result = call_593993.call(nil, query_593994, nil, nil, nil)

var listBackupPlans* = Call_ListBackupPlans_593774(name: "listBackupPlans",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_ListBackupPlans_593775, base: "/", url: url_ListBackupPlans_593776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupSelection_594081 = ref object of OpenApiRestCall_593437
proc url_CreateBackupSelection_594083(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/selections/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateBackupSelection_594082(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies the backup plan to be associated with the selection of resources.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_594084 = path.getOrDefault("backupPlanId")
  valid_594084 = validateParameter(valid_594084, JString, required = true,
                                 default = nil)
  if valid_594084 != nil:
    section.add "backupPlanId", valid_594084
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594085 = header.getOrDefault("X-Amz-Date")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Date", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Security-Token")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Security-Token", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Content-Sha256", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Algorithm")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Algorithm", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Signature")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Signature", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-SignedHeaders", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Credential")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Credential", valid_594091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594093: Call_CreateBackupSelection_594081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ## 
  let valid = call_594093.validator(path, query, header, formData, body)
  let scheme = call_594093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594093.url(scheme.get, call_594093.host, call_594093.base,
                         call_594093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594093, url, valid)

proc call*(call_594094: Call_CreateBackupSelection_594081; backupPlanId: string;
          body: JsonNode): Recallable =
  ## createBackupSelection
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies the backup plan to be associated with the selection of resources.
  ##   body: JObject (required)
  var path_594095 = newJObject()
  var body_594096 = newJObject()
  add(path_594095, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_594096 = body
  result = call_594094.call(path_594095, nil, nil, nil, body_594096)

var createBackupSelection* = Call_CreateBackupSelection_594081(
    name: "createBackupSelection", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_CreateBackupSelection_594082, base: "/",
    url: url_CreateBackupSelection_594083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupSelections_594048 = ref object of OpenApiRestCall_593437
proc url_ListBackupSelections_594050(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/selections/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListBackupSelections_594049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_594065 = path.getOrDefault("backupPlanId")
  valid_594065 = validateParameter(valid_594065, JString, required = true,
                                 default = nil)
  if valid_594065 != nil:
    section.add "backupPlanId", valid_594065
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594066 = query.getOrDefault("NextToken")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "NextToken", valid_594066
  var valid_594067 = query.getOrDefault("maxResults")
  valid_594067 = validateParameter(valid_594067, JInt, required = false, default = nil)
  if valid_594067 != nil:
    section.add "maxResults", valid_594067
  var valid_594068 = query.getOrDefault("nextToken")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "nextToken", valid_594068
  var valid_594069 = query.getOrDefault("MaxResults")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "MaxResults", valid_594069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594070 = header.getOrDefault("X-Amz-Date")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Date", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Security-Token")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Security-Token", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Content-Sha256", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Algorithm")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Algorithm", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Signature")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Signature", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-SignedHeaders", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Credential")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Credential", valid_594076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594077: Call_ListBackupSelections_594048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ## 
  let valid = call_594077.validator(path, query, header, formData, body)
  let scheme = call_594077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594077.url(scheme.get, call_594077.host, call_594077.base,
                         call_594077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594077, url, valid)

proc call*(call_594078: Call_ListBackupSelections_594048; backupPlanId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listBackupSelections
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_594079 = newJObject()
  var query_594080 = newJObject()
  add(path_594079, "backupPlanId", newJString(backupPlanId))
  add(query_594080, "NextToken", newJString(NextToken))
  add(query_594080, "maxResults", newJInt(maxResults))
  add(query_594080, "nextToken", newJString(nextToken))
  add(query_594080, "MaxResults", newJString(MaxResults))
  result = call_594078.call(path_594079, query_594080, nil, nil, nil)

var listBackupSelections* = Call_ListBackupSelections_594048(
    name: "listBackupSelections", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_ListBackupSelections_594049, base: "/",
    url: url_ListBackupSelections_594050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupVault_594111 = ref object of OpenApiRestCall_593437
proc url_CreateBackupVault_594113(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateBackupVault_594112(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594114 = path.getOrDefault("backupVaultName")
  valid_594114 = validateParameter(valid_594114, JString, required = true,
                                 default = nil)
  if valid_594114 != nil:
    section.add "backupVaultName", valid_594114
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594115 = header.getOrDefault("X-Amz-Date")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Date", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Security-Token")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Security-Token", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Content-Sha256", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Algorithm")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Algorithm", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-Signature")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Signature", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-SignedHeaders", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Credential")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Credential", valid_594121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594123: Call_CreateBackupVault_594111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ## 
  let valid = call_594123.validator(path, query, header, formData, body)
  let scheme = call_594123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594123.url(scheme.get, call_594123.host, call_594123.base,
                         call_594123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594123, url, valid)

proc call*(call_594124: Call_CreateBackupVault_594111; backupVaultName: string;
          body: JsonNode): Recallable =
  ## createBackupVault
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_594125 = newJObject()
  var body_594126 = newJObject()
  add(path_594125, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_594126 = body
  result = call_594124.call(path_594125, nil, nil, nil, body_594126)

var createBackupVault* = Call_CreateBackupVault_594111(name: "createBackupVault",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_CreateBackupVault_594112, base: "/",
    url: url_CreateBackupVault_594113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupVault_594097 = ref object of OpenApiRestCall_593437
proc url_DescribeBackupVault_594099(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeBackupVault_594098(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns metadata about a backup vault specified by its name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594100 = path.getOrDefault("backupVaultName")
  valid_594100 = validateParameter(valid_594100, JString, required = true,
                                 default = nil)
  if valid_594100 != nil:
    section.add "backupVaultName", valid_594100
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594101 = header.getOrDefault("X-Amz-Date")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Date", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Security-Token")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Security-Token", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Content-Sha256", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-Algorithm")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Algorithm", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Signature")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Signature", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-SignedHeaders", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Credential")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Credential", valid_594107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594108: Call_DescribeBackupVault_594097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a backup vault specified by its name.
  ## 
  let valid = call_594108.validator(path, query, header, formData, body)
  let scheme = call_594108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594108.url(scheme.get, call_594108.host, call_594108.base,
                         call_594108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594108, url, valid)

proc call*(call_594109: Call_DescribeBackupVault_594097; backupVaultName: string): Recallable =
  ## describeBackupVault
  ## Returns metadata about a backup vault specified by its name.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_594110 = newJObject()
  add(path_594110, "backupVaultName", newJString(backupVaultName))
  result = call_594109.call(path_594110, nil, nil, nil, nil)

var describeBackupVault* = Call_DescribeBackupVault_594097(
    name: "describeBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}",
    validator: validate_DescribeBackupVault_594098, base: "/",
    url: url_DescribeBackupVault_594099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVault_594127 = ref object of OpenApiRestCall_593437
proc url_DeleteBackupVault_594129(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBackupVault_594128(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and theAWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594130 = path.getOrDefault("backupVaultName")
  valid_594130 = validateParameter(valid_594130, JString, required = true,
                                 default = nil)
  if valid_594130 != nil:
    section.add "backupVaultName", valid_594130
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594131 = header.getOrDefault("X-Amz-Date")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Date", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Security-Token")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Security-Token", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Content-Sha256", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Algorithm")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Algorithm", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Signature")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Signature", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-SignedHeaders", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Credential")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Credential", valid_594137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_DeleteBackupVault_594127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ## 
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_DeleteBackupVault_594127; backupVaultName: string): Recallable =
  ## deleteBackupVault
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and theAWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_594140 = newJObject()
  add(path_594140, "backupVaultName", newJString(backupVaultName))
  result = call_594139.call(path_594140, nil, nil, nil, nil)

var deleteBackupVault* = Call_DeleteBackupVault_594127(name: "deleteBackupVault",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_DeleteBackupVault_594128, base: "/",
    url: url_DeleteBackupVault_594129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBackupPlan_594141 = ref object of OpenApiRestCall_593437
proc url_UpdateBackupPlan_594143(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateBackupPlan_594142(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_594144 = path.getOrDefault("backupPlanId")
  valid_594144 = validateParameter(valid_594144, JString, required = true,
                                 default = nil)
  if valid_594144 != nil:
    section.add "backupPlanId", valid_594144
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594145 = header.getOrDefault("X-Amz-Date")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Date", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Security-Token")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Security-Token", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Content-Sha256", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Algorithm")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Algorithm", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Signature")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Signature", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-SignedHeaders", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Credential")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Credential", valid_594151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594153: Call_UpdateBackupPlan_594141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ## 
  let valid = call_594153.validator(path, query, header, formData, body)
  let scheme = call_594153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594153.url(scheme.get, call_594153.host, call_594153.base,
                         call_594153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594153, url, valid)

proc call*(call_594154: Call_UpdateBackupPlan_594141; backupPlanId: string;
          body: JsonNode): Recallable =
  ## updateBackupPlan
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   body: JObject (required)
  var path_594155 = newJObject()
  var body_594156 = newJObject()
  add(path_594155, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_594156 = body
  result = call_594154.call(path_594155, nil, nil, nil, body_594156)

var updateBackupPlan* = Call_UpdateBackupPlan_594141(name: "updateBackupPlan",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_UpdateBackupPlan_594142,
    base: "/", url: url_UpdateBackupPlan_594143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupPlan_594157 = ref object of OpenApiRestCall_593437
proc url_DeleteBackupPlan_594159(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBackupPlan_594158(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_594160 = path.getOrDefault("backupPlanId")
  valid_594160 = validateParameter(valid_594160, JString, required = true,
                                 default = nil)
  if valid_594160 != nil:
    section.add "backupPlanId", valid_594160
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594161 = header.getOrDefault("X-Amz-Date")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Date", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Security-Token")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Security-Token", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Content-Sha256", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Algorithm")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Algorithm", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Signature")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Signature", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-SignedHeaders", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Credential")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Credential", valid_594167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594168: Call_DeleteBackupPlan_594157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ## 
  let valid = call_594168.validator(path, query, header, formData, body)
  let scheme = call_594168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594168.url(scheme.get, call_594168.host, call_594168.base,
                         call_594168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594168, url, valid)

proc call*(call_594169: Call_DeleteBackupPlan_594157; backupPlanId: string): Recallable =
  ## deleteBackupPlan
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_594170 = newJObject()
  add(path_594170, "backupPlanId", newJString(backupPlanId))
  result = call_594169.call(path_594170, nil, nil, nil, nil)

var deleteBackupPlan* = Call_DeleteBackupPlan_594157(name: "deleteBackupPlan",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_DeleteBackupPlan_594158,
    base: "/", url: url_DeleteBackupPlan_594159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupSelection_594171 = ref object of OpenApiRestCall_593437
proc url_GetBackupSelection_594173(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  assert "selectionId" in path, "`selectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/selections/"),
               (kind: VariableSegment, value: "selectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBackupSelection_594172(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: JString (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_594174 = path.getOrDefault("backupPlanId")
  valid_594174 = validateParameter(valid_594174, JString, required = true,
                                 default = nil)
  if valid_594174 != nil:
    section.add "backupPlanId", valid_594174
  var valid_594175 = path.getOrDefault("selectionId")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = nil)
  if valid_594175 != nil:
    section.add "selectionId", valid_594175
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594176 = header.getOrDefault("X-Amz-Date")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Date", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Security-Token")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Security-Token", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Content-Sha256", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Algorithm")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Algorithm", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-SignedHeaders", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Credential")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Credential", valid_594182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594183: Call_GetBackupSelection_594171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ## 
  let valid = call_594183.validator(path, query, header, formData, body)
  let scheme = call_594183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594183.url(scheme.get, call_594183.host, call_594183.base,
                         call_594183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594183, url, valid)

proc call*(call_594184: Call_GetBackupSelection_594171; backupPlanId: string;
          selectionId: string): Recallable =
  ## getBackupSelection
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_594185 = newJObject()
  add(path_594185, "backupPlanId", newJString(backupPlanId))
  add(path_594185, "selectionId", newJString(selectionId))
  result = call_594184.call(path_594185, nil, nil, nil, nil)

var getBackupSelection* = Call_GetBackupSelection_594171(
    name: "getBackupSelection", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_GetBackupSelection_594172, base: "/",
    url: url_GetBackupSelection_594173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupSelection_594186 = ref object of OpenApiRestCall_593437
proc url_DeleteBackupSelection_594188(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  assert "selectionId" in path, "`selectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/selections/"),
               (kind: VariableSegment, value: "selectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBackupSelection_594187(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: JString (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_594189 = path.getOrDefault("backupPlanId")
  valid_594189 = validateParameter(valid_594189, JString, required = true,
                                 default = nil)
  if valid_594189 != nil:
    section.add "backupPlanId", valid_594189
  var valid_594190 = path.getOrDefault("selectionId")
  valid_594190 = validateParameter(valid_594190, JString, required = true,
                                 default = nil)
  if valid_594190 != nil:
    section.add "selectionId", valid_594190
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594191 = header.getOrDefault("X-Amz-Date")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Date", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Security-Token")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Security-Token", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Content-Sha256", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Algorithm")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Algorithm", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Signature")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Signature", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-SignedHeaders", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Credential")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Credential", valid_594197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594198: Call_DeleteBackupSelection_594186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ## 
  let valid = call_594198.validator(path, query, header, formData, body)
  let scheme = call_594198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594198.url(scheme.get, call_594198.host, call_594198.base,
                         call_594198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594198, url, valid)

proc call*(call_594199: Call_DeleteBackupSelection_594186; backupPlanId: string;
          selectionId: string): Recallable =
  ## deleteBackupSelection
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_594200 = newJObject()
  add(path_594200, "backupPlanId", newJString(backupPlanId))
  add(path_594200, "selectionId", newJString(selectionId))
  result = call_594199.call(path_594200, nil, nil, nil, nil)

var deleteBackupSelection* = Call_DeleteBackupSelection_594186(
    name: "deleteBackupSelection", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_DeleteBackupSelection_594187, base: "/",
    url: url_DeleteBackupSelection_594188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultAccessPolicy_594215 = ref object of OpenApiRestCall_593437
proc url_PutBackupVaultAccessPolicy_594217(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBackupVaultAccessPolicy_594216(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594218 = path.getOrDefault("backupVaultName")
  valid_594218 = validateParameter(valid_594218, JString, required = true,
                                 default = nil)
  if valid_594218 != nil:
    section.add "backupVaultName", valid_594218
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594219 = header.getOrDefault("X-Amz-Date")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Date", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Security-Token")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Security-Token", valid_594220
  var valid_594221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Content-Sha256", valid_594221
  var valid_594222 = header.getOrDefault("X-Amz-Algorithm")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Algorithm", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Signature")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Signature", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-SignedHeaders", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Credential")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Credential", valid_594225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594227: Call_PutBackupVaultAccessPolicy_594215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ## 
  let valid = call_594227.validator(path, query, header, formData, body)
  let scheme = call_594227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594227.url(scheme.get, call_594227.host, call_594227.base,
                         call_594227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594227, url, valid)

proc call*(call_594228: Call_PutBackupVaultAccessPolicy_594215;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultAccessPolicy
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_594229 = newJObject()
  var body_594230 = newJObject()
  add(path_594229, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_594230 = body
  result = call_594228.call(path_594229, nil, nil, nil, body_594230)

var putBackupVaultAccessPolicy* = Call_PutBackupVaultAccessPolicy_594215(
    name: "putBackupVaultAccessPolicy", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_PutBackupVaultAccessPolicy_594216, base: "/",
    url: url_PutBackupVaultAccessPolicy_594217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultAccessPolicy_594201 = ref object of OpenApiRestCall_593437
proc url_GetBackupVaultAccessPolicy_594203(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBackupVaultAccessPolicy_594202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the access policy document that is associated with the named backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594204 = path.getOrDefault("backupVaultName")
  valid_594204 = validateParameter(valid_594204, JString, required = true,
                                 default = nil)
  if valid_594204 != nil:
    section.add "backupVaultName", valid_594204
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594205 = header.getOrDefault("X-Amz-Date")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Date", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Security-Token")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Security-Token", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Content-Sha256", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Algorithm")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Algorithm", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Signature")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Signature", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-SignedHeaders", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Credential")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Credential", valid_594211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594212: Call_GetBackupVaultAccessPolicy_594201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access policy document that is associated with the named backup vault.
  ## 
  let valid = call_594212.validator(path, query, header, formData, body)
  let scheme = call_594212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594212.url(scheme.get, call_594212.host, call_594212.base,
                         call_594212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594212, url, valid)

proc call*(call_594213: Call_GetBackupVaultAccessPolicy_594201;
          backupVaultName: string): Recallable =
  ## getBackupVaultAccessPolicy
  ## Returns the access policy document that is associated with the named backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_594214 = newJObject()
  add(path_594214, "backupVaultName", newJString(backupVaultName))
  result = call_594213.call(path_594214, nil, nil, nil, nil)

var getBackupVaultAccessPolicy* = Call_GetBackupVaultAccessPolicy_594201(
    name: "getBackupVaultAccessPolicy", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_GetBackupVaultAccessPolicy_594202, base: "/",
    url: url_GetBackupVaultAccessPolicy_594203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultAccessPolicy_594231 = ref object of OpenApiRestCall_593437
proc url_DeleteBackupVaultAccessPolicy_594233(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBackupVaultAccessPolicy_594232(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the policy document that manages permissions on a backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594234 = path.getOrDefault("backupVaultName")
  valid_594234 = validateParameter(valid_594234, JString, required = true,
                                 default = nil)
  if valid_594234 != nil:
    section.add "backupVaultName", valid_594234
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594235 = header.getOrDefault("X-Amz-Date")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Date", valid_594235
  var valid_594236 = header.getOrDefault("X-Amz-Security-Token")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Security-Token", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Content-Sha256", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Algorithm")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Algorithm", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Signature")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Signature", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-SignedHeaders", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Credential")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Credential", valid_594241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594242: Call_DeleteBackupVaultAccessPolicy_594231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy document that manages permissions on a backup vault.
  ## 
  let valid = call_594242.validator(path, query, header, formData, body)
  let scheme = call_594242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594242.url(scheme.get, call_594242.host, call_594242.base,
                         call_594242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594242, url, valid)

proc call*(call_594243: Call_DeleteBackupVaultAccessPolicy_594231;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultAccessPolicy
  ## Deletes the policy document that manages permissions on a backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_594244 = newJObject()
  add(path_594244, "backupVaultName", newJString(backupVaultName))
  result = call_594243.call(path_594244, nil, nil, nil, nil)

var deleteBackupVaultAccessPolicy* = Call_DeleteBackupVaultAccessPolicy_594231(
    name: "deleteBackupVaultAccessPolicy", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_DeleteBackupVaultAccessPolicy_594232, base: "/",
    url: url_DeleteBackupVaultAccessPolicy_594233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultNotifications_594259 = ref object of OpenApiRestCall_593437
proc url_PutBackupVaultNotifications_594261(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBackupVaultNotifications_594260(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Turns on notifications on a backup vault for the specified topic and events.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594262 = path.getOrDefault("backupVaultName")
  valid_594262 = validateParameter(valid_594262, JString, required = true,
                                 default = nil)
  if valid_594262 != nil:
    section.add "backupVaultName", valid_594262
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594263 = header.getOrDefault("X-Amz-Date")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Date", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Security-Token")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Security-Token", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Content-Sha256", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Algorithm")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Algorithm", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Signature")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Signature", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-SignedHeaders", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Credential")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Credential", valid_594269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594271: Call_PutBackupVaultNotifications_594259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on notifications on a backup vault for the specified topic and events.
  ## 
  let valid = call_594271.validator(path, query, header, formData, body)
  let scheme = call_594271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594271.url(scheme.get, call_594271.host, call_594271.base,
                         call_594271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594271, url, valid)

proc call*(call_594272: Call_PutBackupVaultNotifications_594259;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultNotifications
  ## Turns on notifications on a backup vault for the specified topic and events.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_594273 = newJObject()
  var body_594274 = newJObject()
  add(path_594273, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_594274 = body
  result = call_594272.call(path_594273, nil, nil, nil, body_594274)

var putBackupVaultNotifications* = Call_PutBackupVaultNotifications_594259(
    name: "putBackupVaultNotifications", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_PutBackupVaultNotifications_594260, base: "/",
    url: url_PutBackupVaultNotifications_594261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultNotifications_594245 = ref object of OpenApiRestCall_593437
proc url_GetBackupVaultNotifications_594247(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBackupVaultNotifications_594246(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns event notifications for the specified backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594248 = path.getOrDefault("backupVaultName")
  valid_594248 = validateParameter(valid_594248, JString, required = true,
                                 default = nil)
  if valid_594248 != nil:
    section.add "backupVaultName", valid_594248
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594249 = header.getOrDefault("X-Amz-Date")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Date", valid_594249
  var valid_594250 = header.getOrDefault("X-Amz-Security-Token")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Security-Token", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Content-Sha256", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Algorithm")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Algorithm", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Signature")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Signature", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-SignedHeaders", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Credential")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Credential", valid_594255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594256: Call_GetBackupVaultNotifications_594245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns event notifications for the specified backup vault.
  ## 
  let valid = call_594256.validator(path, query, header, formData, body)
  let scheme = call_594256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594256.url(scheme.get, call_594256.host, call_594256.base,
                         call_594256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594256, url, valid)

proc call*(call_594257: Call_GetBackupVaultNotifications_594245;
          backupVaultName: string): Recallable =
  ## getBackupVaultNotifications
  ## Returns event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_594258 = newJObject()
  add(path_594258, "backupVaultName", newJString(backupVaultName))
  result = call_594257.call(path_594258, nil, nil, nil, nil)

var getBackupVaultNotifications* = Call_GetBackupVaultNotifications_594245(
    name: "getBackupVaultNotifications", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_GetBackupVaultNotifications_594246, base: "/",
    url: url_GetBackupVaultNotifications_594247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultNotifications_594275 = ref object of OpenApiRestCall_593437
proc url_DeleteBackupVaultNotifications_594277(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBackupVaultNotifications_594276(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes event notifications for the specified backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594278 = path.getOrDefault("backupVaultName")
  valid_594278 = validateParameter(valid_594278, JString, required = true,
                                 default = nil)
  if valid_594278 != nil:
    section.add "backupVaultName", valid_594278
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594279 = header.getOrDefault("X-Amz-Date")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Date", valid_594279
  var valid_594280 = header.getOrDefault("X-Amz-Security-Token")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Security-Token", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Content-Sha256", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Algorithm")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Algorithm", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Signature")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Signature", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-SignedHeaders", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Credential")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Credential", valid_594285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594286: Call_DeleteBackupVaultNotifications_594275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes event notifications for the specified backup vault.
  ## 
  let valid = call_594286.validator(path, query, header, formData, body)
  let scheme = call_594286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594286.url(scheme.get, call_594286.host, call_594286.base,
                         call_594286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594286, url, valid)

proc call*(call_594287: Call_DeleteBackupVaultNotifications_594275;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultNotifications
  ## Deletes event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_594288 = newJObject()
  add(path_594288, "backupVaultName", newJString(backupVaultName))
  result = call_594287.call(path_594288, nil, nil, nil, nil)

var deleteBackupVaultNotifications* = Call_DeleteBackupVaultNotifications_594275(
    name: "deleteBackupVaultNotifications", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_DeleteBackupVaultNotifications_594276, base: "/",
    url: url_DeleteBackupVaultNotifications_594277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecoveryPointLifecycle_594304 = ref object of OpenApiRestCall_593437
proc url_UpdateRecoveryPointLifecycle_594306(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
        "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/"),
               (kind: VariableSegment, value: "recoveryPointArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateRecoveryPointLifecycle_594305(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: JString (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594307 = path.getOrDefault("backupVaultName")
  valid_594307 = validateParameter(valid_594307, JString, required = true,
                                 default = nil)
  if valid_594307 != nil:
    section.add "backupVaultName", valid_594307
  var valid_594308 = path.getOrDefault("recoveryPointArn")
  valid_594308 = validateParameter(valid_594308, JString, required = true,
                                 default = nil)
  if valid_594308 != nil:
    section.add "recoveryPointArn", valid_594308
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594309 = header.getOrDefault("X-Amz-Date")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Date", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Security-Token")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Security-Token", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Content-Sha256", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Algorithm")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Algorithm", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-Signature")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-Signature", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-SignedHeaders", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-Credential")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Credential", valid_594315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594317: Call_UpdateRecoveryPointLifecycle_594304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ## 
  let valid = call_594317.validator(path, query, header, formData, body)
  let scheme = call_594317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594317.url(scheme.get, call_594317.host, call_594317.base,
                         call_594317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594317, url, valid)

proc call*(call_594318: Call_UpdateRecoveryPointLifecycle_594304;
          backupVaultName: string; recoveryPointArn: string; body: JsonNode): Recallable =
  ## updateRecoveryPointLifecycle
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   body: JObject (required)
  var path_594319 = newJObject()
  var body_594320 = newJObject()
  add(path_594319, "backupVaultName", newJString(backupVaultName))
  add(path_594319, "recoveryPointArn", newJString(recoveryPointArn))
  if body != nil:
    body_594320 = body
  result = call_594318.call(path_594319, nil, nil, nil, body_594320)

var updateRecoveryPointLifecycle* = Call_UpdateRecoveryPointLifecycle_594304(
    name: "updateRecoveryPointLifecycle", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_UpdateRecoveryPointLifecycle_594305, base: "/",
    url: url_UpdateRecoveryPointLifecycle_594306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecoveryPoint_594289 = ref object of OpenApiRestCall_593437
proc url_DescribeRecoveryPoint_594291(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
        "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/"),
               (kind: VariableSegment, value: "recoveryPointArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeRecoveryPoint_594290(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: JString (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594292 = path.getOrDefault("backupVaultName")
  valid_594292 = validateParameter(valid_594292, JString, required = true,
                                 default = nil)
  if valid_594292 != nil:
    section.add "backupVaultName", valid_594292
  var valid_594293 = path.getOrDefault("recoveryPointArn")
  valid_594293 = validateParameter(valid_594293, JString, required = true,
                                 default = nil)
  if valid_594293 != nil:
    section.add "recoveryPointArn", valid_594293
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594294 = header.getOrDefault("X-Amz-Date")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Date", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Security-Token")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Security-Token", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Content-Sha256", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Algorithm")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Algorithm", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Signature")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Signature", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-SignedHeaders", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Credential")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Credential", valid_594300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594301: Call_DescribeRecoveryPoint_594289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ## 
  let valid = call_594301.validator(path, query, header, formData, body)
  let scheme = call_594301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594301.url(scheme.get, call_594301.host, call_594301.base,
                         call_594301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594301, url, valid)

proc call*(call_594302: Call_DescribeRecoveryPoint_594289; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## describeRecoveryPoint
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_594303 = newJObject()
  add(path_594303, "backupVaultName", newJString(backupVaultName))
  add(path_594303, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_594302.call(path_594303, nil, nil, nil, nil)

var describeRecoveryPoint* = Call_DescribeRecoveryPoint_594289(
    name: "describeRecoveryPoint", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DescribeRecoveryPoint_594290, base: "/",
    url: url_DescribeRecoveryPoint_594291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRecoveryPoint_594321 = ref object of OpenApiRestCall_593437
proc url_DeleteRecoveryPoint_594323(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
        "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/"),
               (kind: VariableSegment, value: "recoveryPointArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteRecoveryPoint_594322(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the recovery point specified by a recovery point ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: JString (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594324 = path.getOrDefault("backupVaultName")
  valid_594324 = validateParameter(valid_594324, JString, required = true,
                                 default = nil)
  if valid_594324 != nil:
    section.add "backupVaultName", valid_594324
  var valid_594325 = path.getOrDefault("recoveryPointArn")
  valid_594325 = validateParameter(valid_594325, JString, required = true,
                                 default = nil)
  if valid_594325 != nil:
    section.add "recoveryPointArn", valid_594325
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594326 = header.getOrDefault("X-Amz-Date")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Date", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Security-Token")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Security-Token", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Content-Sha256", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Algorithm")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Algorithm", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Signature")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Signature", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-SignedHeaders", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Credential")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Credential", valid_594332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594333: Call_DeleteRecoveryPoint_594321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recovery point specified by a recovery point ID.
  ## 
  let valid = call_594333.validator(path, query, header, formData, body)
  let scheme = call_594333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594333.url(scheme.get, call_594333.host, call_594333.base,
                         call_594333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594333, url, valid)

proc call*(call_594334: Call_DeleteRecoveryPoint_594321; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## deleteRecoveryPoint
  ## Deletes the recovery point specified by a recovery point ID.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_594335 = newJObject()
  add(path_594335, "backupVaultName", newJString(backupVaultName))
  add(path_594335, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_594334.call(path_594335, nil, nil, nil, nil)

var deleteRecoveryPoint* = Call_DeleteRecoveryPoint_594321(
    name: "deleteRecoveryPoint", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DeleteRecoveryPoint_594322, base: "/",
    url: url_DeleteRecoveryPoint_594323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBackupJob_594350 = ref object of OpenApiRestCall_593437
proc url_StopBackupJob_594352(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupJobId" in path, "`backupJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-jobs/"),
               (kind: VariableSegment, value: "backupJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_StopBackupJob_594351(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupJobId: JString (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupJobId` field"
  var valid_594353 = path.getOrDefault("backupJobId")
  valid_594353 = validateParameter(valid_594353, JString, required = true,
                                 default = nil)
  if valid_594353 != nil:
    section.add "backupJobId", valid_594353
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594354 = header.getOrDefault("X-Amz-Date")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Date", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Security-Token")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Security-Token", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Content-Sha256", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-Algorithm")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Algorithm", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-Signature")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-Signature", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-SignedHeaders", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-Credential")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Credential", valid_594360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594361: Call_StopBackupJob_594350; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ## 
  let valid = call_594361.validator(path, query, header, formData, body)
  let scheme = call_594361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594361.url(scheme.get, call_594361.host, call_594361.base,
                         call_594361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594361, url, valid)

proc call*(call_594362: Call_StopBackupJob_594350; backupJobId: string): Recallable =
  ## stopBackupJob
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_594363 = newJObject()
  add(path_594363, "backupJobId", newJString(backupJobId))
  result = call_594362.call(path_594363, nil, nil, nil, nil)

var stopBackupJob* = Call_StopBackupJob_594350(name: "stopBackupJob",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_StopBackupJob_594351,
    base: "/", url: url_StopBackupJob_594352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupJob_594336 = ref object of OpenApiRestCall_593437
proc url_DescribeBackupJob_594338(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupJobId" in path, "`backupJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-jobs/"),
               (kind: VariableSegment, value: "backupJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeBackupJob_594337(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns metadata associated with creating a backup of a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupJobId: JString (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupJobId` field"
  var valid_594339 = path.getOrDefault("backupJobId")
  valid_594339 = validateParameter(valid_594339, JString, required = true,
                                 default = nil)
  if valid_594339 != nil:
    section.add "backupJobId", valid_594339
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594340 = header.getOrDefault("X-Amz-Date")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Date", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Security-Token")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Security-Token", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Content-Sha256", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Algorithm")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Algorithm", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Signature")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Signature", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-SignedHeaders", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Credential")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Credential", valid_594346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594347: Call_DescribeBackupJob_594336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with creating a backup of a resource.
  ## 
  let valid = call_594347.validator(path, query, header, formData, body)
  let scheme = call_594347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594347.url(scheme.get, call_594347.host, call_594347.base,
                         call_594347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594347, url, valid)

proc call*(call_594348: Call_DescribeBackupJob_594336; backupJobId: string): Recallable =
  ## describeBackupJob
  ## Returns metadata associated with creating a backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_594349 = newJObject()
  add(path_594349, "backupJobId", newJString(backupJobId))
  result = call_594348.call(path_594349, nil, nil, nil, nil)

var describeBackupJob* = Call_DescribeBackupJob_594336(name: "describeBackupJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_DescribeBackupJob_594337,
    base: "/", url: url_DescribeBackupJob_594338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProtectedResource_594364 = ref object of OpenApiRestCall_593437
proc url_DescribeProtectedResource_594366(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeProtectedResource_594365(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the resource type.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594367 = path.getOrDefault("resourceArn")
  valid_594367 = validateParameter(valid_594367, JString, required = true,
                                 default = nil)
  if valid_594367 != nil:
    section.add "resourceArn", valid_594367
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594368 = header.getOrDefault("X-Amz-Date")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Date", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Security-Token")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Security-Token", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Content-Sha256", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-Algorithm")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-Algorithm", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Signature")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Signature", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-SignedHeaders", valid_594373
  var valid_594374 = header.getOrDefault("X-Amz-Credential")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Credential", valid_594374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594375: Call_DescribeProtectedResource_594364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ## 
  let valid = call_594375.validator(path, query, header, formData, body)
  let scheme = call_594375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594375.url(scheme.get, call_594375.host, call_594375.base,
                         call_594375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594375, url, valid)

proc call*(call_594376: Call_DescribeProtectedResource_594364; resourceArn: string): Recallable =
  ## describeProtectedResource
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the resource type.
  var path_594377 = newJObject()
  add(path_594377, "resourceArn", newJString(resourceArn))
  result = call_594376.call(path_594377, nil, nil, nil, nil)

var describeProtectedResource* = Call_DescribeProtectedResource_594364(
    name: "describeProtectedResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/{resourceArn}",
    validator: validate_DescribeProtectedResource_594365, base: "/",
    url: url_DescribeProtectedResource_594366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRestoreJob_594378 = ref object of OpenApiRestCall_593437
proc url_DescribeRestoreJob_594380(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restoreJobId" in path, "`restoreJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restore-jobs/"),
               (kind: VariableSegment, value: "restoreJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeRestoreJob_594379(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restoreJobId: JString (required)
  ##               : Uniquely identifies the job that restores a recovery point.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restoreJobId` field"
  var valid_594381 = path.getOrDefault("restoreJobId")
  valid_594381 = validateParameter(valid_594381, JString, required = true,
                                 default = nil)
  if valid_594381 != nil:
    section.add "restoreJobId", valid_594381
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594382 = header.getOrDefault("X-Amz-Date")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Date", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Security-Token")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Security-Token", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Content-Sha256", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Algorithm")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Algorithm", valid_594385
  var valid_594386 = header.getOrDefault("X-Amz-Signature")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-Signature", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-SignedHeaders", valid_594387
  var valid_594388 = header.getOrDefault("X-Amz-Credential")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "X-Amz-Credential", valid_594388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594389: Call_DescribeRestoreJob_594378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ## 
  let valid = call_594389.validator(path, query, header, formData, body)
  let scheme = call_594389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594389.url(scheme.get, call_594389.host, call_594389.base,
                         call_594389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594389, url, valid)

proc call*(call_594390: Call_DescribeRestoreJob_594378; restoreJobId: string): Recallable =
  ## describeRestoreJob
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ##   restoreJobId: string (required)
  ##               : Uniquely identifies the job that restores a recovery point.
  var path_594391 = newJObject()
  add(path_594391, "restoreJobId", newJString(restoreJobId))
  result = call_594390.call(path_594391, nil, nil, nil, nil)

var describeRestoreJob* = Call_DescribeRestoreJob_594378(
    name: "describeRestoreJob", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/restore-jobs/{restoreJobId}",
    validator: validate_DescribeRestoreJob_594379, base: "/",
    url: url_DescribeRestoreJob_594380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBackupPlanTemplate_594392 = ref object of OpenApiRestCall_593437
proc url_ExportBackupPlanTemplate_594394(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/toTemplate/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ExportBackupPlanTemplate_594393(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_594395 = path.getOrDefault("backupPlanId")
  valid_594395 = validateParameter(valid_594395, JString, required = true,
                                 default = nil)
  if valid_594395 != nil:
    section.add "backupPlanId", valid_594395
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594396 = header.getOrDefault("X-Amz-Date")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Date", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Security-Token")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Security-Token", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Content-Sha256", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Algorithm")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Algorithm", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Signature")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Signature", valid_594400
  var valid_594401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-SignedHeaders", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Credential")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Credential", valid_594402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594403: Call_ExportBackupPlanTemplate_594392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ## 
  let valid = call_594403.validator(path, query, header, formData, body)
  let scheme = call_594403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594403.url(scheme.get, call_594403.host, call_594403.base,
                         call_594403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594403, url, valid)

proc call*(call_594404: Call_ExportBackupPlanTemplate_594392; backupPlanId: string): Recallable =
  ## exportBackupPlanTemplate
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_594405 = newJObject()
  add(path_594405, "backupPlanId", newJString(backupPlanId))
  result = call_594404.call(path_594405, nil, nil, nil, nil)

var exportBackupPlanTemplate* = Call_ExportBackupPlanTemplate_594392(
    name: "exportBackupPlanTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/toTemplate/",
    validator: validate_ExportBackupPlanTemplate_594393, base: "/",
    url: url_ExportBackupPlanTemplate_594394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlan_594406 = ref object of OpenApiRestCall_593437
proc url_GetBackupPlan_594408(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBackupPlan_594407(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_594409 = path.getOrDefault("backupPlanId")
  valid_594409 = validateParameter(valid_594409, JString, required = true,
                                 default = nil)
  if valid_594409 != nil:
    section.add "backupPlanId", valid_594409
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  section = newJObject()
  var valid_594410 = query.getOrDefault("versionId")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "versionId", valid_594410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594411 = header.getOrDefault("X-Amz-Date")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Date", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Security-Token")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Security-Token", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Content-Sha256", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Algorithm")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Algorithm", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Signature")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Signature", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-SignedHeaders", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Credential")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Credential", valid_594417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594418: Call_GetBackupPlan_594406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ## 
  let valid = call_594418.validator(path, query, header, formData, body)
  let scheme = call_594418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594418.url(scheme.get, call_594418.host, call_594418.base,
                         call_594418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594418, url, valid)

proc call*(call_594419: Call_GetBackupPlan_594406; backupPlanId: string;
          versionId: string = ""): Recallable =
  ## getBackupPlan
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ##   versionId: string
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_594420 = newJObject()
  var query_594421 = newJObject()
  add(query_594421, "versionId", newJString(versionId))
  add(path_594420, "backupPlanId", newJString(backupPlanId))
  result = call_594419.call(path_594420, query_594421, nil, nil, nil)

var getBackupPlan* = Call_GetBackupPlan_594406(name: "getBackupPlan",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/", validator: validate_GetBackupPlan_594407,
    base: "/", url: url_GetBackupPlan_594408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromJSON_594422 = ref object of OpenApiRestCall_593437
proc url_GetBackupPlanFromJSON_594424(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBackupPlanFromJSON_594423(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a valid JSON document specifying a backup plan or an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594425 = header.getOrDefault("X-Amz-Date")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Date", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Security-Token")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Security-Token", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Content-Sha256", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Algorithm")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Algorithm", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Signature")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Signature", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-SignedHeaders", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Credential")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Credential", valid_594431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594433: Call_GetBackupPlanFromJSON_594422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a valid JSON document specifying a backup plan or an error.
  ## 
  let valid = call_594433.validator(path, query, header, formData, body)
  let scheme = call_594433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594433.url(scheme.get, call_594433.host, call_594433.base,
                         call_594433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594433, url, valid)

proc call*(call_594434: Call_GetBackupPlanFromJSON_594422; body: JsonNode): Recallable =
  ## getBackupPlanFromJSON
  ## Returns a valid JSON document specifying a backup plan or an error.
  ##   body: JObject (required)
  var body_594435 = newJObject()
  if body != nil:
    body_594435 = body
  result = call_594434.call(nil, nil, nil, nil, body_594435)

var getBackupPlanFromJSON* = Call_GetBackupPlanFromJSON_594422(
    name: "getBackupPlanFromJSON", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup/template/json/toPlan",
    validator: validate_GetBackupPlanFromJSON_594423, base: "/",
    url: url_GetBackupPlanFromJSON_594424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromTemplate_594436 = ref object of OpenApiRestCall_593437
proc url_GetBackupPlanFromTemplate_594438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "templateId" in path, "`templateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/template/plans/"),
               (kind: VariableSegment, value: "templateId"),
               (kind: ConstantSegment, value: "/toPlan")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBackupPlanFromTemplate_594437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   templateId: JString (required)
  ##             : Uniquely identifies a stored backup plan template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `templateId` field"
  var valid_594439 = path.getOrDefault("templateId")
  valid_594439 = validateParameter(valid_594439, JString, required = true,
                                 default = nil)
  if valid_594439 != nil:
    section.add "templateId", valid_594439
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594440 = header.getOrDefault("X-Amz-Date")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Date", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Security-Token")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Security-Token", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Content-Sha256", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Algorithm")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Algorithm", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Signature")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Signature", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-SignedHeaders", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-Credential")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-Credential", valid_594446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594447: Call_GetBackupPlanFromTemplate_594436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ## 
  let valid = call_594447.validator(path, query, header, formData, body)
  let scheme = call_594447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594447.url(scheme.get, call_594447.host, call_594447.base,
                         call_594447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594447, url, valid)

proc call*(call_594448: Call_GetBackupPlanFromTemplate_594436; templateId: string): Recallable =
  ## getBackupPlanFromTemplate
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ##   templateId: string (required)
  ##             : Uniquely identifies a stored backup plan template.
  var path_594449 = newJObject()
  add(path_594449, "templateId", newJString(templateId))
  result = call_594448.call(path_594449, nil, nil, nil, nil)

var getBackupPlanFromTemplate* = Call_GetBackupPlanFromTemplate_594436(
    name: "getBackupPlanFromTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/template/plans/{templateId}/toPlan",
    validator: validate_GetBackupPlanFromTemplate_594437, base: "/",
    url: url_GetBackupPlanFromTemplate_594438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecoveryPointRestoreMetadata_594450 = ref object of OpenApiRestCall_593437
proc url_GetRecoveryPointRestoreMetadata_594452(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
        "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/"),
               (kind: VariableSegment, value: "recoveryPointArn"),
               (kind: ConstantSegment, value: "/restore-metadata")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetRecoveryPointRestoreMetadata_594451(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns two sets of metadata key-value pairs. The first set lists the metadata that the recovery point was created with. The second set lists the metadata key-value pairs that are required to restore the recovery point.</p> <p>These sets can be the same, or the restore metadata set can contain different values if the target service to be restored has changed since the recovery point was created and now requires additional or different information in order to be restored.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: JString (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594453 = path.getOrDefault("backupVaultName")
  valid_594453 = validateParameter(valid_594453, JString, required = true,
                                 default = nil)
  if valid_594453 != nil:
    section.add "backupVaultName", valid_594453
  var valid_594454 = path.getOrDefault("recoveryPointArn")
  valid_594454 = validateParameter(valid_594454, JString, required = true,
                                 default = nil)
  if valid_594454 != nil:
    section.add "recoveryPointArn", valid_594454
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594455 = header.getOrDefault("X-Amz-Date")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Date", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Security-Token")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Security-Token", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Content-Sha256", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Algorithm")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Algorithm", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Signature")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Signature", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-SignedHeaders", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-Credential")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Credential", valid_594461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594462: Call_GetRecoveryPointRestoreMetadata_594450;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns two sets of metadata key-value pairs. The first set lists the metadata that the recovery point was created with. The second set lists the metadata key-value pairs that are required to restore the recovery point.</p> <p>These sets can be the same, or the restore metadata set can contain different values if the target service to be restored has changed since the recovery point was created and now requires additional or different information in order to be restored.</p>
  ## 
  let valid = call_594462.validator(path, query, header, formData, body)
  let scheme = call_594462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594462.url(scheme.get, call_594462.host, call_594462.base,
                         call_594462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594462, url, valid)

proc call*(call_594463: Call_GetRecoveryPointRestoreMetadata_594450;
          backupVaultName: string; recoveryPointArn: string): Recallable =
  ## getRecoveryPointRestoreMetadata
  ## <p>Returns two sets of metadata key-value pairs. The first set lists the metadata that the recovery point was created with. The second set lists the metadata key-value pairs that are required to restore the recovery point.</p> <p>These sets can be the same, or the restore metadata set can contain different values if the target service to be restored has changed since the recovery point was created and now requires additional or different information in order to be restored.</p>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_594464 = newJObject()
  add(path_594464, "backupVaultName", newJString(backupVaultName))
  add(path_594464, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_594463.call(path_594464, nil, nil, nil, nil)

var getRecoveryPointRestoreMetadata* = Call_GetRecoveryPointRestoreMetadata_594450(
    name: "getRecoveryPointRestoreMetadata", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}/restore-metadata",
    validator: validate_GetRecoveryPointRestoreMetadata_594451, base: "/",
    url: url_GetRecoveryPointRestoreMetadata_594452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSupportedResourceTypes_594465 = ref object of OpenApiRestCall_593437
proc url_GetSupportedResourceTypes_594467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSupportedResourceTypes_594466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the AWS resource types supported by AWS Backup.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594468 = header.getOrDefault("X-Amz-Date")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-Date", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Security-Token")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Security-Token", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Content-Sha256", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Algorithm")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Algorithm", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-Signature")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-Signature", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-SignedHeaders", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Credential")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Credential", valid_594474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594475: Call_GetSupportedResourceTypes_594465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the AWS resource types supported by AWS Backup.
  ## 
  let valid = call_594475.validator(path, query, header, formData, body)
  let scheme = call_594475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594475.url(scheme.get, call_594475.host, call_594475.base,
                         call_594475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594475, url, valid)

proc call*(call_594476: Call_GetSupportedResourceTypes_594465): Recallable =
  ## getSupportedResourceTypes
  ## Returns the AWS resource types supported by AWS Backup.
  result = call_594476.call(nil, nil, nil, nil, nil)

var getSupportedResourceTypes* = Call_GetSupportedResourceTypes_594465(
    name: "getSupportedResourceTypes", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/supported-resource-types",
    validator: validate_GetSupportedResourceTypes_594466, base: "/",
    url: url_GetSupportedResourceTypes_594467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupJobs_594477 = ref object of OpenApiRestCall_593437
proc url_ListBackupJobs_594479(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBackupJobs_594478(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns metadata about your backup jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   createdBefore: JString
  ##                : Returns only backup jobs that were created before the specified date.
  ##   createdAfter: JString
  ##               : Returns only backup jobs that were created after the specified date.
  ##   resourceArn: JString
  ##              : Returns only backup jobs that match the specified resource Amazon Resource Name (ARN).
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   backupVaultName: JString
  ##                  : Returns only backup jobs that will be stored in the specified backup vault. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   state: JString
  ##        : Returns only backup jobs that are in the specified state.
  ##   resourceType: JString
  ##               : <p>Returns only backup jobs for the specified resources:</p> <ul> <li> <p> <code>EBS</code> for Amazon Elastic Block Store</p> </li> <li> <p> <code>SGW</code> for AWS Storage Gateway</p> </li> <li> <p> <code>RDS</code> for Amazon Relational Database Service</p> </li> <li> <p> <code>DDB</code> for Amazon DynamoDB</p> </li> <li> <p> <code>EFS</code> for Amazon Elastic File System</p> </li> </ul>
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594480 = query.getOrDefault("createdBefore")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "createdBefore", valid_594480
  var valid_594481 = query.getOrDefault("createdAfter")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "createdAfter", valid_594481
  var valid_594482 = query.getOrDefault("resourceArn")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "resourceArn", valid_594482
  var valid_594483 = query.getOrDefault("NextToken")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "NextToken", valid_594483
  var valid_594484 = query.getOrDefault("maxResults")
  valid_594484 = validateParameter(valid_594484, JInt, required = false, default = nil)
  if valid_594484 != nil:
    section.add "maxResults", valid_594484
  var valid_594485 = query.getOrDefault("nextToken")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "nextToken", valid_594485
  var valid_594486 = query.getOrDefault("backupVaultName")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "backupVaultName", valid_594486
  var valid_594500 = query.getOrDefault("state")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = newJString("CREATED"))
  if valid_594500 != nil:
    section.add "state", valid_594500
  var valid_594501 = query.getOrDefault("resourceType")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "resourceType", valid_594501
  var valid_594502 = query.getOrDefault("MaxResults")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "MaxResults", valid_594502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594503 = header.getOrDefault("X-Amz-Date")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Date", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Security-Token")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Security-Token", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Content-Sha256", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Algorithm")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Algorithm", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Signature")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Signature", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-SignedHeaders", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Credential")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Credential", valid_594509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594510: Call_ListBackupJobs_594477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about your backup jobs.
  ## 
  let valid = call_594510.validator(path, query, header, formData, body)
  let scheme = call_594510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594510.url(scheme.get, call_594510.host, call_594510.base,
                         call_594510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594510, url, valid)

proc call*(call_594511: Call_ListBackupJobs_594477; createdBefore: string = "";
          createdAfter: string = ""; resourceArn: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; backupVaultName: string = "";
          state: string = "CREATED"; resourceType: string = ""; MaxResults: string = ""): Recallable =
  ## listBackupJobs
  ## Returns metadata about your backup jobs.
  ##   createdBefore: string
  ##                : Returns only backup jobs that were created before the specified date.
  ##   createdAfter: string
  ##               : Returns only backup jobs that were created after the specified date.
  ##   resourceArn: string
  ##              : Returns only backup jobs that match the specified resource Amazon Resource Name (ARN).
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   backupVaultName: string
  ##                  : Returns only backup jobs that will be stored in the specified backup vault. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   state: string
  ##        : Returns only backup jobs that are in the specified state.
  ##   resourceType: string
  ##               : <p>Returns only backup jobs for the specified resources:</p> <ul> <li> <p> <code>EBS</code> for Amazon Elastic Block Store</p> </li> <li> <p> <code>SGW</code> for AWS Storage Gateway</p> </li> <li> <p> <code>RDS</code> for Amazon Relational Database Service</p> </li> <li> <p> <code>DDB</code> for Amazon DynamoDB</p> </li> <li> <p> <code>EFS</code> for Amazon Elastic File System</p> </li> </ul>
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594512 = newJObject()
  add(query_594512, "createdBefore", newJString(createdBefore))
  add(query_594512, "createdAfter", newJString(createdAfter))
  add(query_594512, "resourceArn", newJString(resourceArn))
  add(query_594512, "NextToken", newJString(NextToken))
  add(query_594512, "maxResults", newJInt(maxResults))
  add(query_594512, "nextToken", newJString(nextToken))
  add(query_594512, "backupVaultName", newJString(backupVaultName))
  add(query_594512, "state", newJString(state))
  add(query_594512, "resourceType", newJString(resourceType))
  add(query_594512, "MaxResults", newJString(MaxResults))
  result = call_594511.call(nil, query_594512, nil, nil, nil)

var listBackupJobs* = Call_ListBackupJobs_594477(name: "listBackupJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup-jobs/",
    validator: validate_ListBackupJobs_594478, base: "/", url: url_ListBackupJobs_594479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanTemplates_594513 = ref object of OpenApiRestCall_593437
proc url_ListBackupPlanTemplates_594515(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBackupPlanTemplates_594514(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594516 = query.getOrDefault("NextToken")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "NextToken", valid_594516
  var valid_594517 = query.getOrDefault("maxResults")
  valid_594517 = validateParameter(valid_594517, JInt, required = false, default = nil)
  if valid_594517 != nil:
    section.add "maxResults", valid_594517
  var valid_594518 = query.getOrDefault("nextToken")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "nextToken", valid_594518
  var valid_594519 = query.getOrDefault("MaxResults")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "MaxResults", valid_594519
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594520 = header.getOrDefault("X-Amz-Date")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Date", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Security-Token")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Security-Token", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Content-Sha256", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Algorithm")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Algorithm", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Signature")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Signature", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-SignedHeaders", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-Credential")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Credential", valid_594526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594527: Call_ListBackupPlanTemplates_594513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ## 
  let valid = call_594527.validator(path, query, header, formData, body)
  let scheme = call_594527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594527.url(scheme.get, call_594527.host, call_594527.base,
                         call_594527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594527, url, valid)

proc call*(call_594528: Call_ListBackupPlanTemplates_594513;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listBackupPlanTemplates
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594529 = newJObject()
  add(query_594529, "NextToken", newJString(NextToken))
  add(query_594529, "maxResults", newJInt(maxResults))
  add(query_594529, "nextToken", newJString(nextToken))
  add(query_594529, "MaxResults", newJString(MaxResults))
  result = call_594528.call(nil, query_594529, nil, nil, nil)

var listBackupPlanTemplates* = Call_ListBackupPlanTemplates_594513(
    name: "listBackupPlanTemplates", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/template/plans",
    validator: validate_ListBackupPlanTemplates_594514, base: "/",
    url: url_ListBackupPlanTemplates_594515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanVersions_594530 = ref object of OpenApiRestCall_593437
proc url_ListBackupPlanVersions_594532(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/versions/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListBackupPlanVersions_594531(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_594533 = path.getOrDefault("backupPlanId")
  valid_594533 = validateParameter(valid_594533, JString, required = true,
                                 default = nil)
  if valid_594533 != nil:
    section.add "backupPlanId", valid_594533
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594534 = query.getOrDefault("NextToken")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "NextToken", valid_594534
  var valid_594535 = query.getOrDefault("maxResults")
  valid_594535 = validateParameter(valid_594535, JInt, required = false, default = nil)
  if valid_594535 != nil:
    section.add "maxResults", valid_594535
  var valid_594536 = query.getOrDefault("nextToken")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "nextToken", valid_594536
  var valid_594537 = query.getOrDefault("MaxResults")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "MaxResults", valid_594537
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594538 = header.getOrDefault("X-Amz-Date")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Date", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Security-Token")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Security-Token", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Content-Sha256", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-Algorithm")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Algorithm", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Signature")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Signature", valid_594542
  var valid_594543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594543 = validateParameter(valid_594543, JString, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "X-Amz-SignedHeaders", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Credential")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Credential", valid_594544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594545: Call_ListBackupPlanVersions_594530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ## 
  let valid = call_594545.validator(path, query, header, formData, body)
  let scheme = call_594545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594545.url(scheme.get, call_594545.host, call_594545.base,
                         call_594545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594545, url, valid)

proc call*(call_594546: Call_ListBackupPlanVersions_594530; backupPlanId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listBackupPlanVersions
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_594547 = newJObject()
  var query_594548 = newJObject()
  add(path_594547, "backupPlanId", newJString(backupPlanId))
  add(query_594548, "NextToken", newJString(NextToken))
  add(query_594548, "maxResults", newJInt(maxResults))
  add(query_594548, "nextToken", newJString(nextToken))
  add(query_594548, "MaxResults", newJString(MaxResults))
  result = call_594546.call(path_594547, query_594548, nil, nil, nil)

var listBackupPlanVersions* = Call_ListBackupPlanVersions_594530(
    name: "listBackupPlanVersions", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/plans/{backupPlanId}/versions/",
    validator: validate_ListBackupPlanVersions_594531, base: "/",
    url: url_ListBackupPlanVersions_594532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupVaults_594549 = ref object of OpenApiRestCall_593437
proc url_ListBackupVaults_594551(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBackupVaults_594550(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of recovery point storage containers along with information about them.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594552 = query.getOrDefault("NextToken")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "NextToken", valid_594552
  var valid_594553 = query.getOrDefault("maxResults")
  valid_594553 = validateParameter(valid_594553, JInt, required = false, default = nil)
  if valid_594553 != nil:
    section.add "maxResults", valid_594553
  var valid_594554 = query.getOrDefault("nextToken")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "nextToken", valid_594554
  var valid_594555 = query.getOrDefault("MaxResults")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "MaxResults", valid_594555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594556 = header.getOrDefault("X-Amz-Date")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Date", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Security-Token")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Security-Token", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-Content-Sha256", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Algorithm")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Algorithm", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Signature")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Signature", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-SignedHeaders", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-Credential")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Credential", valid_594562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594563: Call_ListBackupVaults_594549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of recovery point storage containers along with information about them.
  ## 
  let valid = call_594563.validator(path, query, header, formData, body)
  let scheme = call_594563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594563.url(scheme.get, call_594563.host, call_594563.base,
                         call_594563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594563, url, valid)

proc call*(call_594564: Call_ListBackupVaults_594549; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBackupVaults
  ## Returns a list of recovery point storage containers along with information about them.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594565 = newJObject()
  add(query_594565, "NextToken", newJString(NextToken))
  add(query_594565, "maxResults", newJInt(maxResults))
  add(query_594565, "nextToken", newJString(nextToken))
  add(query_594565, "MaxResults", newJString(MaxResults))
  result = call_594564.call(nil, query_594565, nil, nil, nil)

var listBackupVaults* = Call_ListBackupVaults_594549(name: "listBackupVaults",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-vaults/", validator: validate_ListBackupVaults_594550,
    base: "/", url: url_ListBackupVaults_594551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProtectedResources_594566 = ref object of OpenApiRestCall_593437
proc url_ListProtectedResources_594568(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProtectedResources_594567(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594569 = query.getOrDefault("NextToken")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "NextToken", valid_594569
  var valid_594570 = query.getOrDefault("maxResults")
  valid_594570 = validateParameter(valid_594570, JInt, required = false, default = nil)
  if valid_594570 != nil:
    section.add "maxResults", valid_594570
  var valid_594571 = query.getOrDefault("nextToken")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "nextToken", valid_594571
  var valid_594572 = query.getOrDefault("MaxResults")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "MaxResults", valid_594572
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594573 = header.getOrDefault("X-Amz-Date")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-Date", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Security-Token")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Security-Token", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Content-Sha256", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-Algorithm")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Algorithm", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Signature")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Signature", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-SignedHeaders", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Credential")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Credential", valid_594579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594580: Call_ListProtectedResources_594566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ## 
  let valid = call_594580.validator(path, query, header, formData, body)
  let scheme = call_594580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594580.url(scheme.get, call_594580.host, call_594580.base,
                         call_594580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594580, url, valid)

proc call*(call_594581: Call_ListProtectedResources_594566; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listProtectedResources
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594582 = newJObject()
  add(query_594582, "NextToken", newJString(NextToken))
  add(query_594582, "maxResults", newJInt(maxResults))
  add(query_594582, "nextToken", newJString(nextToken))
  add(query_594582, "MaxResults", newJString(MaxResults))
  result = call_594581.call(nil, query_594582, nil, nil, nil)

var listProtectedResources* = Call_ListProtectedResources_594566(
    name: "listProtectedResources", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/",
    validator: validate_ListProtectedResources_594567, base: "/",
    url: url_ListProtectedResources_594568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByBackupVault_594583 = ref object of OpenApiRestCall_593437
proc url_ListRecoveryPointsByBackupVault_594585(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListRecoveryPointsByBackupVault_594584(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about the recovery points stored in a backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_594586 = path.getOrDefault("backupVaultName")
  valid_594586 = validateParameter(valid_594586, JString, required = true,
                                 default = nil)
  if valid_594586 != nil:
    section.add "backupVaultName", valid_594586
  result.add "path", section
  ## parameters in `query` object:
  ##   createdBefore: JString
  ##                : Returns only recovery points that were created before the specified timestamp.
  ##   createdAfter: JString
  ##               : Returns only recovery points that were created after the specified timestamp.
  ##   resourceArn: JString
  ##              : Returns only recovery points that match the specified resource Amazon Resource Name (ARN).
  ##   backupPlanId: JString
  ##               : Returns only recovery points that match the specified backup plan ID.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   resourceType: JString
  ##               : Returns only recovery points that match the specified resource type.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594587 = query.getOrDefault("createdBefore")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "createdBefore", valid_594587
  var valid_594588 = query.getOrDefault("createdAfter")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "createdAfter", valid_594588
  var valid_594589 = query.getOrDefault("resourceArn")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "resourceArn", valid_594589
  var valid_594590 = query.getOrDefault("backupPlanId")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "backupPlanId", valid_594590
  var valid_594591 = query.getOrDefault("NextToken")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "NextToken", valid_594591
  var valid_594592 = query.getOrDefault("maxResults")
  valid_594592 = validateParameter(valid_594592, JInt, required = false, default = nil)
  if valid_594592 != nil:
    section.add "maxResults", valid_594592
  var valid_594593 = query.getOrDefault("nextToken")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "nextToken", valid_594593
  var valid_594594 = query.getOrDefault("resourceType")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "resourceType", valid_594594
  var valid_594595 = query.getOrDefault("MaxResults")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "MaxResults", valid_594595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594596 = header.getOrDefault("X-Amz-Date")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Date", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Security-Token")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Security-Token", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-Content-Sha256", valid_594598
  var valid_594599 = header.getOrDefault("X-Amz-Algorithm")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-Algorithm", valid_594599
  var valid_594600 = header.getOrDefault("X-Amz-Signature")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "X-Amz-Signature", valid_594600
  var valid_594601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-SignedHeaders", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Credential")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Credential", valid_594602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594603: Call_ListRecoveryPointsByBackupVault_594583;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns detailed information about the recovery points stored in a backup vault.
  ## 
  let valid = call_594603.validator(path, query, header, formData, body)
  let scheme = call_594603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594603.url(scheme.get, call_594603.host, call_594603.base,
                         call_594603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594603, url, valid)

proc call*(call_594604: Call_ListRecoveryPointsByBackupVault_594583;
          backupVaultName: string; createdBefore: string = "";
          createdAfter: string = ""; resourceArn: string = "";
          backupPlanId: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; resourceType: string = ""; MaxResults: string = ""): Recallable =
  ## listRecoveryPointsByBackupVault
  ## Returns detailed information about the recovery points stored in a backup vault.
  ##   createdBefore: string
  ##                : Returns only recovery points that were created before the specified timestamp.
  ##   createdAfter: string
  ##               : Returns only recovery points that were created after the specified timestamp.
  ##   resourceArn: string
  ##              : Returns only recovery points that match the specified resource Amazon Resource Name (ARN).
  ##   backupPlanId: string
  ##               : Returns only recovery points that match the specified backup plan ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   resourceType: string
  ##               : Returns only recovery points that match the specified resource type.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_594605 = newJObject()
  var query_594606 = newJObject()
  add(query_594606, "createdBefore", newJString(createdBefore))
  add(query_594606, "createdAfter", newJString(createdAfter))
  add(query_594606, "resourceArn", newJString(resourceArn))
  add(query_594606, "backupPlanId", newJString(backupPlanId))
  add(query_594606, "NextToken", newJString(NextToken))
  add(path_594605, "backupVaultName", newJString(backupVaultName))
  add(query_594606, "maxResults", newJInt(maxResults))
  add(query_594606, "nextToken", newJString(nextToken))
  add(query_594606, "resourceType", newJString(resourceType))
  add(query_594606, "MaxResults", newJString(MaxResults))
  result = call_594604.call(path_594605, query_594606, nil, nil, nil)

var listRecoveryPointsByBackupVault* = Call_ListRecoveryPointsByBackupVault_594583(
    name: "listRecoveryPointsByBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/recovery-points/",
    validator: validate_ListRecoveryPointsByBackupVault_594584, base: "/",
    url: url_ListRecoveryPointsByBackupVault_594585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByResource_594607 = ref object of OpenApiRestCall_593437
proc url_ListRecoveryPointsByResource_594609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "/recovery-points/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListRecoveryPointsByResource_594608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the resource type.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594610 = path.getOrDefault("resourceArn")
  valid_594610 = validateParameter(valid_594610, JString, required = true,
                                 default = nil)
  if valid_594610 != nil:
    section.add "resourceArn", valid_594610
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594611 = query.getOrDefault("NextToken")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "NextToken", valid_594611
  var valid_594612 = query.getOrDefault("maxResults")
  valid_594612 = validateParameter(valid_594612, JInt, required = false, default = nil)
  if valid_594612 != nil:
    section.add "maxResults", valid_594612
  var valid_594613 = query.getOrDefault("nextToken")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "nextToken", valid_594613
  var valid_594614 = query.getOrDefault("MaxResults")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "MaxResults", valid_594614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594615 = header.getOrDefault("X-Amz-Date")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Date", valid_594615
  var valid_594616 = header.getOrDefault("X-Amz-Security-Token")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-Security-Token", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Content-Sha256", valid_594617
  var valid_594618 = header.getOrDefault("X-Amz-Algorithm")
  valid_594618 = validateParameter(valid_594618, JString, required = false,
                                 default = nil)
  if valid_594618 != nil:
    section.add "X-Amz-Algorithm", valid_594618
  var valid_594619 = header.getOrDefault("X-Amz-Signature")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Signature", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-SignedHeaders", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Credential")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Credential", valid_594621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594622: Call_ListRecoveryPointsByResource_594607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ## 
  let valid = call_594622.validator(path, query, header, formData, body)
  let scheme = call_594622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594622.url(scheme.get, call_594622.host, call_594622.base,
                         call_594622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594622, url, valid)

proc call*(call_594623: Call_ListRecoveryPointsByResource_594607;
          resourceArn: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRecoveryPointsByResource
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the resource type.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_594624 = newJObject()
  var query_594625 = newJObject()
  add(query_594625, "NextToken", newJString(NextToken))
  add(query_594625, "maxResults", newJInt(maxResults))
  add(query_594625, "nextToken", newJString(nextToken))
  add(path_594624, "resourceArn", newJString(resourceArn))
  add(query_594625, "MaxResults", newJString(MaxResults))
  result = call_594623.call(path_594624, query_594625, nil, nil, nil)

var listRecoveryPointsByResource* = Call_ListRecoveryPointsByResource_594607(
    name: "listRecoveryPointsByResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/resources/{resourceArn}/recovery-points/",
    validator: validate_ListRecoveryPointsByResource_594608, base: "/",
    url: url_ListRecoveryPointsByResource_594609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRestoreJobs_594626 = ref object of OpenApiRestCall_593437
proc url_ListRestoreJobs_594628(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRestoreJobs_594627(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594629 = query.getOrDefault("NextToken")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "NextToken", valid_594629
  var valid_594630 = query.getOrDefault("maxResults")
  valid_594630 = validateParameter(valid_594630, JInt, required = false, default = nil)
  if valid_594630 != nil:
    section.add "maxResults", valid_594630
  var valid_594631 = query.getOrDefault("nextToken")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "nextToken", valid_594631
  var valid_594632 = query.getOrDefault("MaxResults")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "MaxResults", valid_594632
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594633 = header.getOrDefault("X-Amz-Date")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "X-Amz-Date", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Security-Token")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Security-Token", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Content-Sha256", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Algorithm")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Algorithm", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-Signature")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Signature", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-SignedHeaders", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Credential")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Credential", valid_594639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594640: Call_ListRestoreJobs_594626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ## 
  let valid = call_594640.validator(path, query, header, formData, body)
  let scheme = call_594640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594640.url(scheme.get, call_594640.host, call_594640.base,
                         call_594640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594640, url, valid)

proc call*(call_594641: Call_ListRestoreJobs_594626; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRestoreJobs
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594642 = newJObject()
  add(query_594642, "NextToken", newJString(NextToken))
  add(query_594642, "maxResults", newJInt(maxResults))
  add(query_594642, "nextToken", newJString(nextToken))
  add(query_594642, "MaxResults", newJString(MaxResults))
  result = call_594641.call(nil, query_594642, nil, nil, nil)

var listRestoreJobs* = Call_ListRestoreJobs_594626(name: "listRestoreJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/restore-jobs/",
    validator: validate_ListRestoreJobs_594627, base: "/", url: url_ListRestoreJobs_594628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_594643 = ref object of OpenApiRestCall_593437
proc url_ListTags_594645(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTags_594644(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the type of resource. Valid targets for <code>ListTags</code> are recovery points, backup plans, and backup vaults.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594646 = path.getOrDefault("resourceArn")
  valid_594646 = validateParameter(valid_594646, JString, required = true,
                                 default = nil)
  if valid_594646 != nil:
    section.add "resourceArn", valid_594646
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594647 = query.getOrDefault("NextToken")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "NextToken", valid_594647
  var valid_594648 = query.getOrDefault("maxResults")
  valid_594648 = validateParameter(valid_594648, JInt, required = false, default = nil)
  if valid_594648 != nil:
    section.add "maxResults", valid_594648
  var valid_594649 = query.getOrDefault("nextToken")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "nextToken", valid_594649
  var valid_594650 = query.getOrDefault("MaxResults")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "MaxResults", valid_594650
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594651 = header.getOrDefault("X-Amz-Date")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-Date", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-Security-Token")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-Security-Token", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Content-Sha256", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Algorithm")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Algorithm", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Signature")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Signature", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-SignedHeaders", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-Credential")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Credential", valid_594657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594658: Call_ListTags_594643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ## 
  let valid = call_594658.validator(path, query, header, formData, body)
  let scheme = call_594658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594658.url(scheme.get, call_594658.host, call_594658.base,
                         call_594658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594658, url, valid)

proc call*(call_594659: Call_ListTags_594643; resourceArn: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTags
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the type of resource. Valid targets for <code>ListTags</code> are recovery points, backup plans, and backup vaults.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_594660 = newJObject()
  var query_594661 = newJObject()
  add(query_594661, "NextToken", newJString(NextToken))
  add(query_594661, "maxResults", newJInt(maxResults))
  add(query_594661, "nextToken", newJString(nextToken))
  add(path_594660, "resourceArn", newJString(resourceArn))
  add(query_594661, "MaxResults", newJString(MaxResults))
  result = call_594659.call(path_594660, query_594661, nil, nil, nil)

var listTags* = Call_ListTags_594643(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "backup.amazonaws.com",
                                  route: "/tags/{resourceArn}/",
                                  validator: validate_ListTags_594644, base: "/",
                                  url: url_ListTags_594645,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBackupJob_594662 = ref object of OpenApiRestCall_593437
proc url_StartBackupJob_594664(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartBackupJob_594663(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Starts a job to create a one-time backup of the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594665 = header.getOrDefault("X-Amz-Date")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Date", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Security-Token")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Security-Token", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Content-Sha256", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Algorithm")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Algorithm", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Signature")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Signature", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-SignedHeaders", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Credential")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Credential", valid_594671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594673: Call_StartBackupJob_594662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to create a one-time backup of the specified resource.
  ## 
  let valid = call_594673.validator(path, query, header, formData, body)
  let scheme = call_594673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594673.url(scheme.get, call_594673.host, call_594673.base,
                         call_594673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594673, url, valid)

proc call*(call_594674: Call_StartBackupJob_594662; body: JsonNode): Recallable =
  ## startBackupJob
  ## Starts a job to create a one-time backup of the specified resource.
  ##   body: JObject (required)
  var body_594675 = newJObject()
  if body != nil:
    body_594675 = body
  result = call_594674.call(nil, nil, nil, nil, body_594675)

var startBackupJob* = Call_StartBackupJob_594662(name: "startBackupJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup-jobs",
    validator: validate_StartBackupJob_594663, base: "/", url: url_StartBackupJob_594664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRestoreJob_594676 = ref object of OpenApiRestCall_593437
proc url_StartRestoreJob_594678(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartRestoreJob_594677(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594679 = header.getOrDefault("X-Amz-Date")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Date", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Security-Token")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Security-Token", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Content-Sha256", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-Algorithm")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-Algorithm", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Signature")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Signature", valid_594683
  var valid_594684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "X-Amz-SignedHeaders", valid_594684
  var valid_594685 = header.getOrDefault("X-Amz-Credential")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "X-Amz-Credential", valid_594685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594687: Call_StartRestoreJob_594676; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ## 
  let valid = call_594687.validator(path, query, header, formData, body)
  let scheme = call_594687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594687.url(scheme.get, call_594687.host, call_594687.base,
                         call_594687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594687, url, valid)

proc call*(call_594688: Call_StartRestoreJob_594676; body: JsonNode): Recallable =
  ## startRestoreJob
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ##   body: JObject (required)
  var body_594689 = newJObject()
  if body != nil:
    body_594689 = body
  result = call_594688.call(nil, nil, nil, nil, body_594689)

var startRestoreJob* = Call_StartRestoreJob_594676(name: "startRestoreJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/restore-jobs",
    validator: validate_StartRestoreJob_594677, base: "/", url: url_StartRestoreJob_594678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594690 = ref object of OpenApiRestCall_593437
proc url_TagResource_594692(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_TagResource_594691(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594693 = path.getOrDefault("resourceArn")
  valid_594693 = validateParameter(valid_594693, JString, required = true,
                                 default = nil)
  if valid_594693 != nil:
    section.add "resourceArn", valid_594693
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594694 = header.getOrDefault("X-Amz-Date")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Date", valid_594694
  var valid_594695 = header.getOrDefault("X-Amz-Security-Token")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Security-Token", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Content-Sha256", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-Algorithm")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-Algorithm", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Signature")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Signature", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-SignedHeaders", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-Credential")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-Credential", valid_594700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594702: Call_TagResource_594690; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ## 
  let valid = call_594702.validator(path, query, header, formData, body)
  let scheme = call_594702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594702.url(scheme.get, call_594702.host, call_594702.base,
                         call_594702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594702, url, valid)

proc call*(call_594703: Call_TagResource_594690; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  var path_594704 = newJObject()
  var body_594705 = newJObject()
  if body != nil:
    body_594705 = body
  add(path_594704, "resourceArn", newJString(resourceArn))
  result = call_594703.call(path_594704, nil, nil, nil, body_594705)

var tagResource* = Call_TagResource_594690(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "backup.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_594691,
                                        base: "/", url: url_TagResource_594692,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594706 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594708(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/untag/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UntagResource_594707(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594709 = path.getOrDefault("resourceArn")
  valid_594709 = validateParameter(valid_594709, JString, required = true,
                                 default = nil)
  if valid_594709 != nil:
    section.add "resourceArn", valid_594709
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594710 = header.getOrDefault("X-Amz-Date")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Date", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Security-Token")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Security-Token", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-Content-Sha256", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Algorithm")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Algorithm", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Signature")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Signature", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-SignedHeaders", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-Credential")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-Credential", valid_594716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594718: Call_UntagResource_594706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ## 
  let valid = call_594718.validator(path, query, header, formData, body)
  let scheme = call_594718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594718.url(scheme.get, call_594718.host, call_594718.base,
                         call_594718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594718, url, valid)

proc call*(call_594719: Call_UntagResource_594706; body: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  var path_594720 = newJObject()
  var body_594721 = newJObject()
  if body != nil:
    body_594721 = body
  add(path_594720, "resourceArn", newJString(resourceArn))
  result = call_594719.call(path_594720, nil, nil, nil, body_594721)

var untagResource* = Call_UntagResource_594706(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/untag/{resourceArn}", validator: validate_UntagResource_594707,
    base: "/", url: url_UntagResource_594708, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
