
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
  Call_CreateBackupPlan_592963 = ref object of OpenApiRestCall_592364
proc url_CreateBackupPlan_592965(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBackupPlan_592964(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592966 = header.getOrDefault("X-Amz-Signature")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Signature", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Content-Sha256", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Date")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Date", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Credential")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Credential", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-Security-Token")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-Security-Token", valid_592970
  var valid_592971 = header.getOrDefault("X-Amz-Algorithm")
  valid_592971 = validateParameter(valid_592971, JString, required = false,
                                 default = nil)
  if valid_592971 != nil:
    section.add "X-Amz-Algorithm", valid_592971
  var valid_592972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592972 = validateParameter(valid_592972, JString, required = false,
                                 default = nil)
  if valid_592972 != nil:
    section.add "X-Amz-SignedHeaders", valid_592972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592974: Call_CreateBackupPlan_592963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, the existing <code>backupPlanId</code> is returned.</p>
  ## 
  let valid = call_592974.validator(path, query, header, formData, body)
  let scheme = call_592974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592974.url(scheme.get, call_592974.host, call_592974.base,
                         call_592974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592974, url, valid)

proc call*(call_592975: Call_CreateBackupPlan_592963; body: JsonNode): Recallable =
  ## createBackupPlan
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, the existing <code>backupPlanId</code> is returned.</p>
  ##   body: JObject (required)
  var body_592976 = newJObject()
  if body != nil:
    body_592976 = body
  result = call_592975.call(nil, nil, nil, nil, body_592976)

var createBackupPlan* = Call_CreateBackupPlan_592963(name: "createBackupPlan",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_CreateBackupPlan_592964, base: "/",
    url: url_CreateBackupPlan_592965, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlans_592703 = ref object of OpenApiRestCall_592364
proc url_ListBackupPlans_592705(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBackupPlans_592704(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   includeDeleted: JBool
  ##                 : A Boolean value with a default value of <code>FALSE</code> that returns deleted backup plans when set to <code>TRUE</code>.
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_592817 = query.getOrDefault("nextToken")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "nextToken", valid_592817
  var valid_592818 = query.getOrDefault("MaxResults")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "MaxResults", valid_592818
  var valid_592819 = query.getOrDefault("NextToken")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "NextToken", valid_592819
  var valid_592820 = query.getOrDefault("includeDeleted")
  valid_592820 = validateParameter(valid_592820, JBool, required = false, default = nil)
  if valid_592820 != nil:
    section.add "includeDeleted", valid_592820
  var valid_592821 = query.getOrDefault("maxResults")
  valid_592821 = validateParameter(valid_592821, JInt, required = false, default = nil)
  if valid_592821 != nil:
    section.add "maxResults", valid_592821
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592822 = header.getOrDefault("X-Amz-Signature")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Signature", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Content-Sha256", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Date")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Date", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-Credential")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-Credential", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Security-Token")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Security-Token", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-Algorithm")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-Algorithm", valid_592827
  var valid_592828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592828 = validateParameter(valid_592828, JString, required = false,
                                 default = nil)
  if valid_592828 != nil:
    section.add "X-Amz-SignedHeaders", valid_592828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592851: Call_ListBackupPlans_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ## 
  let valid = call_592851.validator(path, query, header, formData, body)
  let scheme = call_592851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592851.url(scheme.get, call_592851.host, call_592851.base,
                         call_592851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592851, url, valid)

proc call*(call_592922: Call_ListBackupPlans_592703; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; includeDeleted: bool = false;
          maxResults: int = 0): Recallable =
  ## listBackupPlans
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   includeDeleted: bool
  ##                 : A Boolean value with a default value of <code>FALSE</code> that returns deleted backup plans when set to <code>TRUE</code>.
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_592923 = newJObject()
  add(query_592923, "nextToken", newJString(nextToken))
  add(query_592923, "MaxResults", newJString(MaxResults))
  add(query_592923, "NextToken", newJString(NextToken))
  add(query_592923, "includeDeleted", newJBool(includeDeleted))
  add(query_592923, "maxResults", newJInt(maxResults))
  result = call_592922.call(nil, query_592923, nil, nil, nil)

var listBackupPlans* = Call_ListBackupPlans_592703(name: "listBackupPlans",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_ListBackupPlans_592704, base: "/", url: url_ListBackupPlans_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupSelection_593010 = ref object of OpenApiRestCall_592364
proc url_CreateBackupSelection_593012(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackupSelection_593011(path: JsonNode; query: JsonNode;
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
  var valid_593013 = path.getOrDefault("backupPlanId")
  valid_593013 = validateParameter(valid_593013, JString, required = true,
                                 default = nil)
  if valid_593013 != nil:
    section.add "backupPlanId", valid_593013
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593014 = header.getOrDefault("X-Amz-Signature")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Signature", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Content-Sha256", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Date")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Date", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Credential")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Credential", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Security-Token")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Security-Token", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Algorithm")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Algorithm", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-SignedHeaders", valid_593020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593022: Call_CreateBackupSelection_593010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ## 
  let valid = call_593022.validator(path, query, header, formData, body)
  let scheme = call_593022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593022.url(scheme.get, call_593022.host, call_593022.base,
                         call_593022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593022, url, valid)

proc call*(call_593023: Call_CreateBackupSelection_593010; backupPlanId: string;
          body: JsonNode): Recallable =
  ## createBackupSelection
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies the backup plan to be associated with the selection of resources.
  ##   body: JObject (required)
  var path_593024 = newJObject()
  var body_593025 = newJObject()
  add(path_593024, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_593025 = body
  result = call_593023.call(path_593024, nil, nil, nil, body_593025)

var createBackupSelection* = Call_CreateBackupSelection_593010(
    name: "createBackupSelection", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_CreateBackupSelection_593011, base: "/",
    url: url_CreateBackupSelection_593012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupSelections_592977 = ref object of OpenApiRestCall_592364
proc url_ListBackupSelections_592979(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupSelections_592978(path: JsonNode; query: JsonNode;
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
  var valid_592994 = path.getOrDefault("backupPlanId")
  valid_592994 = validateParameter(valid_592994, JString, required = true,
                                 default = nil)
  if valid_592994 != nil:
    section.add "backupPlanId", valid_592994
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_592995 = query.getOrDefault("nextToken")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "nextToken", valid_592995
  var valid_592996 = query.getOrDefault("MaxResults")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "MaxResults", valid_592996
  var valid_592997 = query.getOrDefault("NextToken")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "NextToken", valid_592997
  var valid_592998 = query.getOrDefault("maxResults")
  valid_592998 = validateParameter(valid_592998, JInt, required = false, default = nil)
  if valid_592998 != nil:
    section.add "maxResults", valid_592998
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592999 = header.getOrDefault("X-Amz-Signature")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Signature", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Content-Sha256", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Date")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Date", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Credential")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Credential", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Security-Token")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Security-Token", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Algorithm")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Algorithm", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-SignedHeaders", valid_593005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593006: Call_ListBackupSelections_592977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ## 
  let valid = call_593006.validator(path, query, header, formData, body)
  let scheme = call_593006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593006.url(scheme.get, call_593006.host, call_593006.base,
                         call_593006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593006, url, valid)

proc call*(call_593007: Call_ListBackupSelections_592977; backupPlanId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBackupSelections
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_593008 = newJObject()
  var query_593009 = newJObject()
  add(query_593009, "nextToken", newJString(nextToken))
  add(query_593009, "MaxResults", newJString(MaxResults))
  add(query_593009, "NextToken", newJString(NextToken))
  add(path_593008, "backupPlanId", newJString(backupPlanId))
  add(query_593009, "maxResults", newJInt(maxResults))
  result = call_593007.call(path_593008, query_593009, nil, nil, nil)

var listBackupSelections* = Call_ListBackupSelections_592977(
    name: "listBackupSelections", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_ListBackupSelections_592978, base: "/",
    url: url_ListBackupSelections_592979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupVault_593040 = ref object of OpenApiRestCall_592364
proc url_CreateBackupVault_593042(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackupVault_593041(path: JsonNode; query: JsonNode;
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
  var valid_593043 = path.getOrDefault("backupVaultName")
  valid_593043 = validateParameter(valid_593043, JString, required = true,
                                 default = nil)
  if valid_593043 != nil:
    section.add "backupVaultName", valid_593043
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593044 = header.getOrDefault("X-Amz-Signature")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Signature", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Content-Sha256", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Date")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Date", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Credential")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Credential", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Security-Token")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Security-Token", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Algorithm")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Algorithm", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-SignedHeaders", valid_593050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593052: Call_CreateBackupVault_593040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ## 
  let valid = call_593052.validator(path, query, header, formData, body)
  let scheme = call_593052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593052.url(scheme.get, call_593052.host, call_593052.base,
                         call_593052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593052, url, valid)

proc call*(call_593053: Call_CreateBackupVault_593040; backupVaultName: string;
          body: JsonNode): Recallable =
  ## createBackupVault
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_593054 = newJObject()
  var body_593055 = newJObject()
  add(path_593054, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_593055 = body
  result = call_593053.call(path_593054, nil, nil, nil, body_593055)

var createBackupVault* = Call_CreateBackupVault_593040(name: "createBackupVault",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_CreateBackupVault_593041, base: "/",
    url: url_CreateBackupVault_593042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupVault_593026 = ref object of OpenApiRestCall_592364
proc url_DescribeBackupVault_593028(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBackupVault_593027(path: JsonNode; query: JsonNode;
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
  var valid_593029 = path.getOrDefault("backupVaultName")
  valid_593029 = validateParameter(valid_593029, JString, required = true,
                                 default = nil)
  if valid_593029 != nil:
    section.add "backupVaultName", valid_593029
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593030 = header.getOrDefault("X-Amz-Signature")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Signature", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Content-Sha256", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Date")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Date", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Credential")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Credential", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Security-Token")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Security-Token", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Algorithm")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Algorithm", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-SignedHeaders", valid_593036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593037: Call_DescribeBackupVault_593026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a backup vault specified by its name.
  ## 
  let valid = call_593037.validator(path, query, header, formData, body)
  let scheme = call_593037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593037.url(scheme.get, call_593037.host, call_593037.base,
                         call_593037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593037, url, valid)

proc call*(call_593038: Call_DescribeBackupVault_593026; backupVaultName: string): Recallable =
  ## describeBackupVault
  ## Returns metadata about a backup vault specified by its name.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_593039 = newJObject()
  add(path_593039, "backupVaultName", newJString(backupVaultName))
  result = call_593038.call(path_593039, nil, nil, nil, nil)

var describeBackupVault* = Call_DescribeBackupVault_593026(
    name: "describeBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}",
    validator: validate_DescribeBackupVault_593027, base: "/",
    url: url_DescribeBackupVault_593028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVault_593056 = ref object of OpenApiRestCall_592364
proc url_DeleteBackupVault_593058(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackupVault_593057(path: JsonNode; query: JsonNode;
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
  var valid_593059 = path.getOrDefault("backupVaultName")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = nil)
  if valid_593059 != nil:
    section.add "backupVaultName", valid_593059
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593060 = header.getOrDefault("X-Amz-Signature")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Signature", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Content-Sha256", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Date")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Date", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Credential")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Credential", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Security-Token")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Security-Token", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Algorithm")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Algorithm", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-SignedHeaders", valid_593066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_DeleteBackupVault_593056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_DeleteBackupVault_593056; backupVaultName: string): Recallable =
  ## deleteBackupVault
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and theAWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_593069 = newJObject()
  add(path_593069, "backupVaultName", newJString(backupVaultName))
  result = call_593068.call(path_593069, nil, nil, nil, nil)

var deleteBackupVault* = Call_DeleteBackupVault_593056(name: "deleteBackupVault",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_DeleteBackupVault_593057, base: "/",
    url: url_DeleteBackupVault_593058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBackupPlan_593070 = ref object of OpenApiRestCall_592364
proc url_UpdateBackupPlan_593072(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBackupPlan_593071(path: JsonNode; query: JsonNode;
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
  var valid_593073 = path.getOrDefault("backupPlanId")
  valid_593073 = validateParameter(valid_593073, JString, required = true,
                                 default = nil)
  if valid_593073 != nil:
    section.add "backupPlanId", valid_593073
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593074 = header.getOrDefault("X-Amz-Signature")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Signature", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Content-Sha256", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Date")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Date", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Credential")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Credential", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Security-Token")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Security-Token", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Algorithm")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Algorithm", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-SignedHeaders", valid_593080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593082: Call_UpdateBackupPlan_593070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ## 
  let valid = call_593082.validator(path, query, header, formData, body)
  let scheme = call_593082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593082.url(scheme.get, call_593082.host, call_593082.base,
                         call_593082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593082, url, valid)

proc call*(call_593083: Call_UpdateBackupPlan_593070; backupPlanId: string;
          body: JsonNode): Recallable =
  ## updateBackupPlan
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   body: JObject (required)
  var path_593084 = newJObject()
  var body_593085 = newJObject()
  add(path_593084, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_593085 = body
  result = call_593083.call(path_593084, nil, nil, nil, body_593085)

var updateBackupPlan* = Call_UpdateBackupPlan_593070(name: "updateBackupPlan",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_UpdateBackupPlan_593071,
    base: "/", url: url_UpdateBackupPlan_593072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupPlan_593086 = ref object of OpenApiRestCall_592364
proc url_DeleteBackupPlan_593088(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackupPlan_593087(path: JsonNode; query: JsonNode;
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
  var valid_593089 = path.getOrDefault("backupPlanId")
  valid_593089 = validateParameter(valid_593089, JString, required = true,
                                 default = nil)
  if valid_593089 != nil:
    section.add "backupPlanId", valid_593089
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593090 = header.getOrDefault("X-Amz-Signature")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Signature", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Content-Sha256", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Date")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Date", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Credential")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Credential", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Security-Token")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Security-Token", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Algorithm")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Algorithm", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-SignedHeaders", valid_593096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593097: Call_DeleteBackupPlan_593086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ## 
  let valid = call_593097.validator(path, query, header, formData, body)
  let scheme = call_593097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593097.url(scheme.get, call_593097.host, call_593097.base,
                         call_593097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593097, url, valid)

proc call*(call_593098: Call_DeleteBackupPlan_593086; backupPlanId: string): Recallable =
  ## deleteBackupPlan
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_593099 = newJObject()
  add(path_593099, "backupPlanId", newJString(backupPlanId))
  result = call_593098.call(path_593099, nil, nil, nil, nil)

var deleteBackupPlan* = Call_DeleteBackupPlan_593086(name: "deleteBackupPlan",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_DeleteBackupPlan_593087,
    base: "/", url: url_DeleteBackupPlan_593088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupSelection_593100 = ref object of OpenApiRestCall_592364
proc url_GetBackupSelection_593102(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackupSelection_593101(path: JsonNode; query: JsonNode;
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
  var valid_593103 = path.getOrDefault("backupPlanId")
  valid_593103 = validateParameter(valid_593103, JString, required = true,
                                 default = nil)
  if valid_593103 != nil:
    section.add "backupPlanId", valid_593103
  var valid_593104 = path.getOrDefault("selectionId")
  valid_593104 = validateParameter(valid_593104, JString, required = true,
                                 default = nil)
  if valid_593104 != nil:
    section.add "selectionId", valid_593104
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593105 = header.getOrDefault("X-Amz-Signature")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Signature", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Content-Sha256", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Date")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Date", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Credential")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Credential", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Security-Token")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Security-Token", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Algorithm")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Algorithm", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-SignedHeaders", valid_593111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593112: Call_GetBackupSelection_593100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ## 
  let valid = call_593112.validator(path, query, header, formData, body)
  let scheme = call_593112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593112.url(scheme.get, call_593112.host, call_593112.base,
                         call_593112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593112, url, valid)

proc call*(call_593113: Call_GetBackupSelection_593100; backupPlanId: string;
          selectionId: string): Recallable =
  ## getBackupSelection
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_593114 = newJObject()
  add(path_593114, "backupPlanId", newJString(backupPlanId))
  add(path_593114, "selectionId", newJString(selectionId))
  result = call_593113.call(path_593114, nil, nil, nil, nil)

var getBackupSelection* = Call_GetBackupSelection_593100(
    name: "getBackupSelection", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_GetBackupSelection_593101, base: "/",
    url: url_GetBackupSelection_593102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupSelection_593115 = ref object of OpenApiRestCall_592364
proc url_DeleteBackupSelection_593117(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackupSelection_593116(path: JsonNode; query: JsonNode;
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
  var valid_593118 = path.getOrDefault("backupPlanId")
  valid_593118 = validateParameter(valid_593118, JString, required = true,
                                 default = nil)
  if valid_593118 != nil:
    section.add "backupPlanId", valid_593118
  var valid_593119 = path.getOrDefault("selectionId")
  valid_593119 = validateParameter(valid_593119, JString, required = true,
                                 default = nil)
  if valid_593119 != nil:
    section.add "selectionId", valid_593119
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593120 = header.getOrDefault("X-Amz-Signature")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Signature", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Content-Sha256", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Date")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Date", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Credential")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Credential", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Security-Token")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Security-Token", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Algorithm")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Algorithm", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-SignedHeaders", valid_593126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593127: Call_DeleteBackupSelection_593115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ## 
  let valid = call_593127.validator(path, query, header, formData, body)
  let scheme = call_593127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593127.url(scheme.get, call_593127.host, call_593127.base,
                         call_593127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593127, url, valid)

proc call*(call_593128: Call_DeleteBackupSelection_593115; backupPlanId: string;
          selectionId: string): Recallable =
  ## deleteBackupSelection
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_593129 = newJObject()
  add(path_593129, "backupPlanId", newJString(backupPlanId))
  add(path_593129, "selectionId", newJString(selectionId))
  result = call_593128.call(path_593129, nil, nil, nil, nil)

var deleteBackupSelection* = Call_DeleteBackupSelection_593115(
    name: "deleteBackupSelection", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_DeleteBackupSelection_593116, base: "/",
    url: url_DeleteBackupSelection_593117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultAccessPolicy_593144 = ref object of OpenApiRestCall_592364
proc url_PutBackupVaultAccessPolicy_593146(protocol: Scheme; host: string;
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

proc validate_PutBackupVaultAccessPolicy_593145(path: JsonNode; query: JsonNode;
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
  var valid_593147 = path.getOrDefault("backupVaultName")
  valid_593147 = validateParameter(valid_593147, JString, required = true,
                                 default = nil)
  if valid_593147 != nil:
    section.add "backupVaultName", valid_593147
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593148 = header.getOrDefault("X-Amz-Signature")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Signature", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-Content-Sha256", valid_593149
  var valid_593150 = header.getOrDefault("X-Amz-Date")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-Date", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Credential")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Credential", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Security-Token")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Security-Token", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Algorithm")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Algorithm", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-SignedHeaders", valid_593154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593156: Call_PutBackupVaultAccessPolicy_593144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ## 
  let valid = call_593156.validator(path, query, header, formData, body)
  let scheme = call_593156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593156.url(scheme.get, call_593156.host, call_593156.base,
                         call_593156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593156, url, valid)

proc call*(call_593157: Call_PutBackupVaultAccessPolicy_593144;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultAccessPolicy
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_593158 = newJObject()
  var body_593159 = newJObject()
  add(path_593158, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_593159 = body
  result = call_593157.call(path_593158, nil, nil, nil, body_593159)

var putBackupVaultAccessPolicy* = Call_PutBackupVaultAccessPolicy_593144(
    name: "putBackupVaultAccessPolicy", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_PutBackupVaultAccessPolicy_593145, base: "/",
    url: url_PutBackupVaultAccessPolicy_593146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultAccessPolicy_593130 = ref object of OpenApiRestCall_592364
proc url_GetBackupVaultAccessPolicy_593132(protocol: Scheme; host: string;
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

proc validate_GetBackupVaultAccessPolicy_593131(path: JsonNode; query: JsonNode;
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
  var valid_593133 = path.getOrDefault("backupVaultName")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = nil)
  if valid_593133 != nil:
    section.add "backupVaultName", valid_593133
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593134 = header.getOrDefault("X-Amz-Signature")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Signature", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Content-Sha256", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Date")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Date", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Credential")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Credential", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Security-Token")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Security-Token", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Algorithm")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Algorithm", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-SignedHeaders", valid_593140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593141: Call_GetBackupVaultAccessPolicy_593130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access policy document that is associated with the named backup vault.
  ## 
  let valid = call_593141.validator(path, query, header, formData, body)
  let scheme = call_593141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593141.url(scheme.get, call_593141.host, call_593141.base,
                         call_593141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593141, url, valid)

proc call*(call_593142: Call_GetBackupVaultAccessPolicy_593130;
          backupVaultName: string): Recallable =
  ## getBackupVaultAccessPolicy
  ## Returns the access policy document that is associated with the named backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_593143 = newJObject()
  add(path_593143, "backupVaultName", newJString(backupVaultName))
  result = call_593142.call(path_593143, nil, nil, nil, nil)

var getBackupVaultAccessPolicy* = Call_GetBackupVaultAccessPolicy_593130(
    name: "getBackupVaultAccessPolicy", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_GetBackupVaultAccessPolicy_593131, base: "/",
    url: url_GetBackupVaultAccessPolicy_593132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultAccessPolicy_593160 = ref object of OpenApiRestCall_592364
proc url_DeleteBackupVaultAccessPolicy_593162(protocol: Scheme; host: string;
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

proc validate_DeleteBackupVaultAccessPolicy_593161(path: JsonNode; query: JsonNode;
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
  var valid_593163 = path.getOrDefault("backupVaultName")
  valid_593163 = validateParameter(valid_593163, JString, required = true,
                                 default = nil)
  if valid_593163 != nil:
    section.add "backupVaultName", valid_593163
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593164 = header.getOrDefault("X-Amz-Signature")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Signature", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Content-Sha256", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Date")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Date", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Credential")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Credential", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Security-Token")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Security-Token", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Algorithm")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Algorithm", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-SignedHeaders", valid_593170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593171: Call_DeleteBackupVaultAccessPolicy_593160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy document that manages permissions on a backup vault.
  ## 
  let valid = call_593171.validator(path, query, header, formData, body)
  let scheme = call_593171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593171.url(scheme.get, call_593171.host, call_593171.base,
                         call_593171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593171, url, valid)

proc call*(call_593172: Call_DeleteBackupVaultAccessPolicy_593160;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultAccessPolicy
  ## Deletes the policy document that manages permissions on a backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_593173 = newJObject()
  add(path_593173, "backupVaultName", newJString(backupVaultName))
  result = call_593172.call(path_593173, nil, nil, nil, nil)

var deleteBackupVaultAccessPolicy* = Call_DeleteBackupVaultAccessPolicy_593160(
    name: "deleteBackupVaultAccessPolicy", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_DeleteBackupVaultAccessPolicy_593161, base: "/",
    url: url_DeleteBackupVaultAccessPolicy_593162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultNotifications_593188 = ref object of OpenApiRestCall_592364
proc url_PutBackupVaultNotifications_593190(protocol: Scheme; host: string;
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

proc validate_PutBackupVaultNotifications_593189(path: JsonNode; query: JsonNode;
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
  var valid_593191 = path.getOrDefault("backupVaultName")
  valid_593191 = validateParameter(valid_593191, JString, required = true,
                                 default = nil)
  if valid_593191 != nil:
    section.add "backupVaultName", valid_593191
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593192 = header.getOrDefault("X-Amz-Signature")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Signature", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Content-Sha256", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Date")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Date", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Credential")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Credential", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Security-Token")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Security-Token", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Algorithm")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Algorithm", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-SignedHeaders", valid_593198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593200: Call_PutBackupVaultNotifications_593188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on notifications on a backup vault for the specified topic and events.
  ## 
  let valid = call_593200.validator(path, query, header, formData, body)
  let scheme = call_593200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593200.url(scheme.get, call_593200.host, call_593200.base,
                         call_593200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593200, url, valid)

proc call*(call_593201: Call_PutBackupVaultNotifications_593188;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultNotifications
  ## Turns on notifications on a backup vault for the specified topic and events.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_593202 = newJObject()
  var body_593203 = newJObject()
  add(path_593202, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_593203 = body
  result = call_593201.call(path_593202, nil, nil, nil, body_593203)

var putBackupVaultNotifications* = Call_PutBackupVaultNotifications_593188(
    name: "putBackupVaultNotifications", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_PutBackupVaultNotifications_593189, base: "/",
    url: url_PutBackupVaultNotifications_593190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultNotifications_593174 = ref object of OpenApiRestCall_592364
proc url_GetBackupVaultNotifications_593176(protocol: Scheme; host: string;
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

proc validate_GetBackupVaultNotifications_593175(path: JsonNode; query: JsonNode;
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
  var valid_593177 = path.getOrDefault("backupVaultName")
  valid_593177 = validateParameter(valid_593177, JString, required = true,
                                 default = nil)
  if valid_593177 != nil:
    section.add "backupVaultName", valid_593177
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593178 = header.getOrDefault("X-Amz-Signature")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Signature", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Content-Sha256", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Date")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Date", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Credential")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Credential", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Security-Token")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Security-Token", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Algorithm")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Algorithm", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-SignedHeaders", valid_593184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593185: Call_GetBackupVaultNotifications_593174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns event notifications for the specified backup vault.
  ## 
  let valid = call_593185.validator(path, query, header, formData, body)
  let scheme = call_593185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593185.url(scheme.get, call_593185.host, call_593185.base,
                         call_593185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593185, url, valid)

proc call*(call_593186: Call_GetBackupVaultNotifications_593174;
          backupVaultName: string): Recallable =
  ## getBackupVaultNotifications
  ## Returns event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_593187 = newJObject()
  add(path_593187, "backupVaultName", newJString(backupVaultName))
  result = call_593186.call(path_593187, nil, nil, nil, nil)

var getBackupVaultNotifications* = Call_GetBackupVaultNotifications_593174(
    name: "getBackupVaultNotifications", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_GetBackupVaultNotifications_593175, base: "/",
    url: url_GetBackupVaultNotifications_593176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultNotifications_593204 = ref object of OpenApiRestCall_592364
proc url_DeleteBackupVaultNotifications_593206(protocol: Scheme; host: string;
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

proc validate_DeleteBackupVaultNotifications_593205(path: JsonNode;
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
  var valid_593207 = path.getOrDefault("backupVaultName")
  valid_593207 = validateParameter(valid_593207, JString, required = true,
                                 default = nil)
  if valid_593207 != nil:
    section.add "backupVaultName", valid_593207
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593208 = header.getOrDefault("X-Amz-Signature")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Signature", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Content-Sha256", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Date")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Date", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Credential")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Credential", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Security-Token")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Security-Token", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Algorithm")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Algorithm", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-SignedHeaders", valid_593214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593215: Call_DeleteBackupVaultNotifications_593204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes event notifications for the specified backup vault.
  ## 
  let valid = call_593215.validator(path, query, header, formData, body)
  let scheme = call_593215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593215.url(scheme.get, call_593215.host, call_593215.base,
                         call_593215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593215, url, valid)

proc call*(call_593216: Call_DeleteBackupVaultNotifications_593204;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultNotifications
  ## Deletes event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_593217 = newJObject()
  add(path_593217, "backupVaultName", newJString(backupVaultName))
  result = call_593216.call(path_593217, nil, nil, nil, nil)

var deleteBackupVaultNotifications* = Call_DeleteBackupVaultNotifications_593204(
    name: "deleteBackupVaultNotifications", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_DeleteBackupVaultNotifications_593205, base: "/",
    url: url_DeleteBackupVaultNotifications_593206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecoveryPointLifecycle_593233 = ref object of OpenApiRestCall_592364
proc url_UpdateRecoveryPointLifecycle_593235(protocol: Scheme; host: string;
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

proc validate_UpdateRecoveryPointLifecycle_593234(path: JsonNode; query: JsonNode;
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
  var valid_593236 = path.getOrDefault("backupVaultName")
  valid_593236 = validateParameter(valid_593236, JString, required = true,
                                 default = nil)
  if valid_593236 != nil:
    section.add "backupVaultName", valid_593236
  var valid_593237 = path.getOrDefault("recoveryPointArn")
  valid_593237 = validateParameter(valid_593237, JString, required = true,
                                 default = nil)
  if valid_593237 != nil:
    section.add "recoveryPointArn", valid_593237
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593238 = header.getOrDefault("X-Amz-Signature")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Signature", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Content-Sha256", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Date")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Date", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Credential")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Credential", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Security-Token")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Security-Token", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Algorithm")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Algorithm", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-SignedHeaders", valid_593244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593246: Call_UpdateRecoveryPointLifecycle_593233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ## 
  let valid = call_593246.validator(path, query, header, formData, body)
  let scheme = call_593246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593246.url(scheme.get, call_593246.host, call_593246.base,
                         call_593246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593246, url, valid)

proc call*(call_593247: Call_UpdateRecoveryPointLifecycle_593233;
          backupVaultName: string; recoveryPointArn: string; body: JsonNode): Recallable =
  ## updateRecoveryPointLifecycle
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   body: JObject (required)
  var path_593248 = newJObject()
  var body_593249 = newJObject()
  add(path_593248, "backupVaultName", newJString(backupVaultName))
  add(path_593248, "recoveryPointArn", newJString(recoveryPointArn))
  if body != nil:
    body_593249 = body
  result = call_593247.call(path_593248, nil, nil, nil, body_593249)

var updateRecoveryPointLifecycle* = Call_UpdateRecoveryPointLifecycle_593233(
    name: "updateRecoveryPointLifecycle", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_UpdateRecoveryPointLifecycle_593234, base: "/",
    url: url_UpdateRecoveryPointLifecycle_593235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecoveryPoint_593218 = ref object of OpenApiRestCall_592364
proc url_DescribeRecoveryPoint_593220(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRecoveryPoint_593219(path: JsonNode; query: JsonNode;
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
  var valid_593221 = path.getOrDefault("backupVaultName")
  valid_593221 = validateParameter(valid_593221, JString, required = true,
                                 default = nil)
  if valid_593221 != nil:
    section.add "backupVaultName", valid_593221
  var valid_593222 = path.getOrDefault("recoveryPointArn")
  valid_593222 = validateParameter(valid_593222, JString, required = true,
                                 default = nil)
  if valid_593222 != nil:
    section.add "recoveryPointArn", valid_593222
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593223 = header.getOrDefault("X-Amz-Signature")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Signature", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Content-Sha256", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Date")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Date", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Credential")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Credential", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Security-Token")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Security-Token", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Algorithm")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Algorithm", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-SignedHeaders", valid_593229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593230: Call_DescribeRecoveryPoint_593218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ## 
  let valid = call_593230.validator(path, query, header, formData, body)
  let scheme = call_593230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593230.url(scheme.get, call_593230.host, call_593230.base,
                         call_593230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593230, url, valid)

proc call*(call_593231: Call_DescribeRecoveryPoint_593218; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## describeRecoveryPoint
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_593232 = newJObject()
  add(path_593232, "backupVaultName", newJString(backupVaultName))
  add(path_593232, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_593231.call(path_593232, nil, nil, nil, nil)

var describeRecoveryPoint* = Call_DescribeRecoveryPoint_593218(
    name: "describeRecoveryPoint", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DescribeRecoveryPoint_593219, base: "/",
    url: url_DescribeRecoveryPoint_593220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRecoveryPoint_593250 = ref object of OpenApiRestCall_592364
proc url_DeleteRecoveryPoint_593252(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRecoveryPoint_593251(path: JsonNode; query: JsonNode;
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
  var valid_593253 = path.getOrDefault("backupVaultName")
  valid_593253 = validateParameter(valid_593253, JString, required = true,
                                 default = nil)
  if valid_593253 != nil:
    section.add "backupVaultName", valid_593253
  var valid_593254 = path.getOrDefault("recoveryPointArn")
  valid_593254 = validateParameter(valid_593254, JString, required = true,
                                 default = nil)
  if valid_593254 != nil:
    section.add "recoveryPointArn", valid_593254
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593255 = header.getOrDefault("X-Amz-Signature")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Signature", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Content-Sha256", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Date")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Date", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Credential")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Credential", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Security-Token")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Security-Token", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Algorithm")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Algorithm", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-SignedHeaders", valid_593261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593262: Call_DeleteRecoveryPoint_593250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recovery point specified by a recovery point ID.
  ## 
  let valid = call_593262.validator(path, query, header, formData, body)
  let scheme = call_593262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593262.url(scheme.get, call_593262.host, call_593262.base,
                         call_593262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593262, url, valid)

proc call*(call_593263: Call_DeleteRecoveryPoint_593250; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## deleteRecoveryPoint
  ## Deletes the recovery point specified by a recovery point ID.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_593264 = newJObject()
  add(path_593264, "backupVaultName", newJString(backupVaultName))
  add(path_593264, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_593263.call(path_593264, nil, nil, nil, nil)

var deleteRecoveryPoint* = Call_DeleteRecoveryPoint_593250(
    name: "deleteRecoveryPoint", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DeleteRecoveryPoint_593251, base: "/",
    url: url_DeleteRecoveryPoint_593252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBackupJob_593279 = ref object of OpenApiRestCall_592364
proc url_StopBackupJob_593281(protocol: Scheme; host: string; base: string;
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

proc validate_StopBackupJob_593280(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593282 = path.getOrDefault("backupJobId")
  valid_593282 = validateParameter(valid_593282, JString, required = true,
                                 default = nil)
  if valid_593282 != nil:
    section.add "backupJobId", valid_593282
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593283 = header.getOrDefault("X-Amz-Signature")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-Signature", valid_593283
  var valid_593284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-Content-Sha256", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Date")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Date", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Credential")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Credential", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Security-Token")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Security-Token", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Algorithm")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Algorithm", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-SignedHeaders", valid_593289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593290: Call_StopBackupJob_593279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ## 
  let valid = call_593290.validator(path, query, header, formData, body)
  let scheme = call_593290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593290.url(scheme.get, call_593290.host, call_593290.base,
                         call_593290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593290, url, valid)

proc call*(call_593291: Call_StopBackupJob_593279; backupJobId: string): Recallable =
  ## stopBackupJob
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_593292 = newJObject()
  add(path_593292, "backupJobId", newJString(backupJobId))
  result = call_593291.call(path_593292, nil, nil, nil, nil)

var stopBackupJob* = Call_StopBackupJob_593279(name: "stopBackupJob",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_StopBackupJob_593280,
    base: "/", url: url_StopBackupJob_593281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupJob_593265 = ref object of OpenApiRestCall_592364
proc url_DescribeBackupJob_593267(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBackupJob_593266(path: JsonNode; query: JsonNode;
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
  var valid_593268 = path.getOrDefault("backupJobId")
  valid_593268 = validateParameter(valid_593268, JString, required = true,
                                 default = nil)
  if valid_593268 != nil:
    section.add "backupJobId", valid_593268
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593269 = header.getOrDefault("X-Amz-Signature")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Signature", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Content-Sha256", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Date")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Date", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Credential")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Credential", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Security-Token")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Security-Token", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Algorithm")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Algorithm", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-SignedHeaders", valid_593275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593276: Call_DescribeBackupJob_593265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with creating a backup of a resource.
  ## 
  let valid = call_593276.validator(path, query, header, formData, body)
  let scheme = call_593276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593276.url(scheme.get, call_593276.host, call_593276.base,
                         call_593276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593276, url, valid)

proc call*(call_593277: Call_DescribeBackupJob_593265; backupJobId: string): Recallable =
  ## describeBackupJob
  ## Returns metadata associated with creating a backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_593278 = newJObject()
  add(path_593278, "backupJobId", newJString(backupJobId))
  result = call_593277.call(path_593278, nil, nil, nil, nil)

var describeBackupJob* = Call_DescribeBackupJob_593265(name: "describeBackupJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_DescribeBackupJob_593266,
    base: "/", url: url_DescribeBackupJob_593267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProtectedResource_593293 = ref object of OpenApiRestCall_592364
proc url_DescribeProtectedResource_593295(protocol: Scheme; host: string;
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

proc validate_DescribeProtectedResource_593294(path: JsonNode; query: JsonNode;
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
  var valid_593296 = path.getOrDefault("resourceArn")
  valid_593296 = validateParameter(valid_593296, JString, required = true,
                                 default = nil)
  if valid_593296 != nil:
    section.add "resourceArn", valid_593296
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593297 = header.getOrDefault("X-Amz-Signature")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Signature", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Content-Sha256", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Date")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Date", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Credential")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Credential", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Security-Token")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Security-Token", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Algorithm")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Algorithm", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-SignedHeaders", valid_593303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593304: Call_DescribeProtectedResource_593293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ## 
  let valid = call_593304.validator(path, query, header, formData, body)
  let scheme = call_593304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593304.url(scheme.get, call_593304.host, call_593304.base,
                         call_593304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593304, url, valid)

proc call*(call_593305: Call_DescribeProtectedResource_593293; resourceArn: string): Recallable =
  ## describeProtectedResource
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the resource type.
  var path_593306 = newJObject()
  add(path_593306, "resourceArn", newJString(resourceArn))
  result = call_593305.call(path_593306, nil, nil, nil, nil)

var describeProtectedResource* = Call_DescribeProtectedResource_593293(
    name: "describeProtectedResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/{resourceArn}",
    validator: validate_DescribeProtectedResource_593294, base: "/",
    url: url_DescribeProtectedResource_593295,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRestoreJob_593307 = ref object of OpenApiRestCall_592364
proc url_DescribeRestoreJob_593309(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRestoreJob_593308(path: JsonNode; query: JsonNode;
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
  var valid_593310 = path.getOrDefault("restoreJobId")
  valid_593310 = validateParameter(valid_593310, JString, required = true,
                                 default = nil)
  if valid_593310 != nil:
    section.add "restoreJobId", valid_593310
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593311 = header.getOrDefault("X-Amz-Signature")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Signature", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Content-Sha256", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Date")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Date", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-Credential")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Credential", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Security-Token")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Security-Token", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Algorithm")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Algorithm", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-SignedHeaders", valid_593317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593318: Call_DescribeRestoreJob_593307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ## 
  let valid = call_593318.validator(path, query, header, formData, body)
  let scheme = call_593318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593318.url(scheme.get, call_593318.host, call_593318.base,
                         call_593318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593318, url, valid)

proc call*(call_593319: Call_DescribeRestoreJob_593307; restoreJobId: string): Recallable =
  ## describeRestoreJob
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ##   restoreJobId: string (required)
  ##               : Uniquely identifies the job that restores a recovery point.
  var path_593320 = newJObject()
  add(path_593320, "restoreJobId", newJString(restoreJobId))
  result = call_593319.call(path_593320, nil, nil, nil, nil)

var describeRestoreJob* = Call_DescribeRestoreJob_593307(
    name: "describeRestoreJob", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/restore-jobs/{restoreJobId}",
    validator: validate_DescribeRestoreJob_593308, base: "/",
    url: url_DescribeRestoreJob_593309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBackupPlanTemplate_593321 = ref object of OpenApiRestCall_592364
proc url_ExportBackupPlanTemplate_593323(protocol: Scheme; host: string;
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

proc validate_ExportBackupPlanTemplate_593322(path: JsonNode; query: JsonNode;
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
  var valid_593324 = path.getOrDefault("backupPlanId")
  valid_593324 = validateParameter(valid_593324, JString, required = true,
                                 default = nil)
  if valid_593324 != nil:
    section.add "backupPlanId", valid_593324
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593325 = header.getOrDefault("X-Amz-Signature")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Signature", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Content-Sha256", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-Date")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Date", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-Credential")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-Credential", valid_593328
  var valid_593329 = header.getOrDefault("X-Amz-Security-Token")
  valid_593329 = validateParameter(valid_593329, JString, required = false,
                                 default = nil)
  if valid_593329 != nil:
    section.add "X-Amz-Security-Token", valid_593329
  var valid_593330 = header.getOrDefault("X-Amz-Algorithm")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Algorithm", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-SignedHeaders", valid_593331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593332: Call_ExportBackupPlanTemplate_593321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ## 
  let valid = call_593332.validator(path, query, header, formData, body)
  let scheme = call_593332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593332.url(scheme.get, call_593332.host, call_593332.base,
                         call_593332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593332, url, valid)

proc call*(call_593333: Call_ExportBackupPlanTemplate_593321; backupPlanId: string): Recallable =
  ## exportBackupPlanTemplate
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_593334 = newJObject()
  add(path_593334, "backupPlanId", newJString(backupPlanId))
  result = call_593333.call(path_593334, nil, nil, nil, nil)

var exportBackupPlanTemplate* = Call_ExportBackupPlanTemplate_593321(
    name: "exportBackupPlanTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/toTemplate/",
    validator: validate_ExportBackupPlanTemplate_593322, base: "/",
    url: url_ExportBackupPlanTemplate_593323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlan_593335 = ref object of OpenApiRestCall_592364
proc url_GetBackupPlan_593337(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackupPlan_593336(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593338 = path.getOrDefault("backupPlanId")
  valid_593338 = validateParameter(valid_593338, JString, required = true,
                                 default = nil)
  if valid_593338 != nil:
    section.add "backupPlanId", valid_593338
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  section = newJObject()
  var valid_593339 = query.getOrDefault("versionId")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "versionId", valid_593339
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593340 = header.getOrDefault("X-Amz-Signature")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Signature", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Content-Sha256", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-Date")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-Date", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-Credential")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Credential", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-Security-Token")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Security-Token", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-Algorithm")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-Algorithm", valid_593345
  var valid_593346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-SignedHeaders", valid_593346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593347: Call_GetBackupPlan_593335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ## 
  let valid = call_593347.validator(path, query, header, formData, body)
  let scheme = call_593347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593347.url(scheme.get, call_593347.host, call_593347.base,
                         call_593347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593347, url, valid)

proc call*(call_593348: Call_GetBackupPlan_593335; backupPlanId: string;
          versionId: string = ""): Recallable =
  ## getBackupPlan
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ##   versionId: string
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_593349 = newJObject()
  var query_593350 = newJObject()
  add(query_593350, "versionId", newJString(versionId))
  add(path_593349, "backupPlanId", newJString(backupPlanId))
  result = call_593348.call(path_593349, query_593350, nil, nil, nil)

var getBackupPlan* = Call_GetBackupPlan_593335(name: "getBackupPlan",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/", validator: validate_GetBackupPlan_593336,
    base: "/", url: url_GetBackupPlan_593337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromJSON_593351 = ref object of OpenApiRestCall_592364
proc url_GetBackupPlanFromJSON_593353(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBackupPlanFromJSON_593352(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593354 = header.getOrDefault("X-Amz-Signature")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Signature", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Content-Sha256", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Date")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Date", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Credential")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Credential", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Security-Token")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Security-Token", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Algorithm")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Algorithm", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-SignedHeaders", valid_593360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593362: Call_GetBackupPlanFromJSON_593351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a valid JSON document specifying a backup plan or an error.
  ## 
  let valid = call_593362.validator(path, query, header, formData, body)
  let scheme = call_593362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593362.url(scheme.get, call_593362.host, call_593362.base,
                         call_593362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593362, url, valid)

proc call*(call_593363: Call_GetBackupPlanFromJSON_593351; body: JsonNode): Recallable =
  ## getBackupPlanFromJSON
  ## Returns a valid JSON document specifying a backup plan or an error.
  ##   body: JObject (required)
  var body_593364 = newJObject()
  if body != nil:
    body_593364 = body
  result = call_593363.call(nil, nil, nil, nil, body_593364)

var getBackupPlanFromJSON* = Call_GetBackupPlanFromJSON_593351(
    name: "getBackupPlanFromJSON", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup/template/json/toPlan",
    validator: validate_GetBackupPlanFromJSON_593352, base: "/",
    url: url_GetBackupPlanFromJSON_593353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromTemplate_593365 = ref object of OpenApiRestCall_592364
proc url_GetBackupPlanFromTemplate_593367(protocol: Scheme; host: string;
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

proc validate_GetBackupPlanFromTemplate_593366(path: JsonNode; query: JsonNode;
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
  var valid_593368 = path.getOrDefault("templateId")
  valid_593368 = validateParameter(valid_593368, JString, required = true,
                                 default = nil)
  if valid_593368 != nil:
    section.add "templateId", valid_593368
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593369 = header.getOrDefault("X-Amz-Signature")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Signature", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Content-Sha256", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Date")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Date", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Credential")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Credential", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Security-Token")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Security-Token", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Algorithm")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Algorithm", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-SignedHeaders", valid_593375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593376: Call_GetBackupPlanFromTemplate_593365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ## 
  let valid = call_593376.validator(path, query, header, formData, body)
  let scheme = call_593376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593376.url(scheme.get, call_593376.host, call_593376.base,
                         call_593376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593376, url, valid)

proc call*(call_593377: Call_GetBackupPlanFromTemplate_593365; templateId: string): Recallable =
  ## getBackupPlanFromTemplate
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ##   templateId: string (required)
  ##             : Uniquely identifies a stored backup plan template.
  var path_593378 = newJObject()
  add(path_593378, "templateId", newJString(templateId))
  result = call_593377.call(path_593378, nil, nil, nil, nil)

var getBackupPlanFromTemplate* = Call_GetBackupPlanFromTemplate_593365(
    name: "getBackupPlanFromTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/template/plans/{templateId}/toPlan",
    validator: validate_GetBackupPlanFromTemplate_593366, base: "/",
    url: url_GetBackupPlanFromTemplate_593367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecoveryPointRestoreMetadata_593379 = ref object of OpenApiRestCall_592364
proc url_GetRecoveryPointRestoreMetadata_593381(protocol: Scheme; host: string;
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

proc validate_GetRecoveryPointRestoreMetadata_593380(path: JsonNode;
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
  var valid_593382 = path.getOrDefault("backupVaultName")
  valid_593382 = validateParameter(valid_593382, JString, required = true,
                                 default = nil)
  if valid_593382 != nil:
    section.add "backupVaultName", valid_593382
  var valid_593383 = path.getOrDefault("recoveryPointArn")
  valid_593383 = validateParameter(valid_593383, JString, required = true,
                                 default = nil)
  if valid_593383 != nil:
    section.add "recoveryPointArn", valid_593383
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593384 = header.getOrDefault("X-Amz-Signature")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Signature", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Content-Sha256", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Date")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Date", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Credential")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Credential", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Security-Token")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Security-Token", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Algorithm")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Algorithm", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-SignedHeaders", valid_593390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593391: Call_GetRecoveryPointRestoreMetadata_593379;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns two sets of metadata key-value pairs. The first set lists the metadata that the recovery point was created with. The second set lists the metadata key-value pairs that are required to restore the recovery point.</p> <p>These sets can be the same, or the restore metadata set can contain different values if the target service to be restored has changed since the recovery point was created and now requires additional or different information in order to be restored.</p>
  ## 
  let valid = call_593391.validator(path, query, header, formData, body)
  let scheme = call_593391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593391.url(scheme.get, call_593391.host, call_593391.base,
                         call_593391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593391, url, valid)

proc call*(call_593392: Call_GetRecoveryPointRestoreMetadata_593379;
          backupVaultName: string; recoveryPointArn: string): Recallable =
  ## getRecoveryPointRestoreMetadata
  ## <p>Returns two sets of metadata key-value pairs. The first set lists the metadata that the recovery point was created with. The second set lists the metadata key-value pairs that are required to restore the recovery point.</p> <p>These sets can be the same, or the restore metadata set can contain different values if the target service to be restored has changed since the recovery point was created and now requires additional or different information in order to be restored.</p>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_593393 = newJObject()
  add(path_593393, "backupVaultName", newJString(backupVaultName))
  add(path_593393, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_593392.call(path_593393, nil, nil, nil, nil)

var getRecoveryPointRestoreMetadata* = Call_GetRecoveryPointRestoreMetadata_593379(
    name: "getRecoveryPointRestoreMetadata", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}/restore-metadata",
    validator: validate_GetRecoveryPointRestoreMetadata_593380, base: "/",
    url: url_GetRecoveryPointRestoreMetadata_593381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSupportedResourceTypes_593394 = ref object of OpenApiRestCall_592364
proc url_GetSupportedResourceTypes_593396(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSupportedResourceTypes_593395(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593397 = header.getOrDefault("X-Amz-Signature")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Signature", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Content-Sha256", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-Date")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-Date", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Credential")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Credential", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Security-Token")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Security-Token", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-Algorithm")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-Algorithm", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-SignedHeaders", valid_593403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593404: Call_GetSupportedResourceTypes_593394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the AWS resource types supported by AWS Backup.
  ## 
  let valid = call_593404.validator(path, query, header, formData, body)
  let scheme = call_593404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593404.url(scheme.get, call_593404.host, call_593404.base,
                         call_593404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593404, url, valid)

proc call*(call_593405: Call_GetSupportedResourceTypes_593394): Recallable =
  ## getSupportedResourceTypes
  ## Returns the AWS resource types supported by AWS Backup.
  result = call_593405.call(nil, nil, nil, nil, nil)

var getSupportedResourceTypes* = Call_GetSupportedResourceTypes_593394(
    name: "getSupportedResourceTypes", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/supported-resource-types",
    validator: validate_GetSupportedResourceTypes_593395, base: "/",
    url: url_GetSupportedResourceTypes_593396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupJobs_593406 = ref object of OpenApiRestCall_592364
proc url_ListBackupJobs_593408(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBackupJobs_593407(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns metadata about your backup jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   backupVaultName: JString
  ##                  : Returns only backup jobs that will be stored in the specified backup vault. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   state: JString
  ##        : Returns only backup jobs that are in the specified state.
  ##   NextToken: JString
  ##            : Pagination token
  ##   createdAfter: JString
  ##               : Returns only backup jobs that were created after the specified date.
  ##   resourceType: JString
  ##               : <p>Returns only backup jobs for the specified resources:</p> <ul> <li> <p> <code>EBS</code> for Amazon Elastic Block Store</p> </li> <li> <p> <code>SGW</code> for AWS Storage Gateway</p> </li> <li> <p> <code>RDS</code> for Amazon Relational Database Service</p> </li> <li> <p> <code>DDB</code> for Amazon DynamoDB</p> </li> <li> <p> <code>EFS</code> for Amazon Elastic File System</p> </li> </ul>
  ##   createdBefore: JString
  ##                : Returns only backup jobs that were created before the specified date.
  ##   resourceArn: JString
  ##              : Returns only backup jobs that match the specified resource Amazon Resource Name (ARN).
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_593409 = query.getOrDefault("nextToken")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "nextToken", valid_593409
  var valid_593410 = query.getOrDefault("backupVaultName")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "backupVaultName", valid_593410
  var valid_593411 = query.getOrDefault("MaxResults")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "MaxResults", valid_593411
  var valid_593425 = query.getOrDefault("state")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = newJString("CREATED"))
  if valid_593425 != nil:
    section.add "state", valid_593425
  var valid_593426 = query.getOrDefault("NextToken")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "NextToken", valid_593426
  var valid_593427 = query.getOrDefault("createdAfter")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "createdAfter", valid_593427
  var valid_593428 = query.getOrDefault("resourceType")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "resourceType", valid_593428
  var valid_593429 = query.getOrDefault("createdBefore")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "createdBefore", valid_593429
  var valid_593430 = query.getOrDefault("resourceArn")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "resourceArn", valid_593430
  var valid_593431 = query.getOrDefault("maxResults")
  valid_593431 = validateParameter(valid_593431, JInt, required = false, default = nil)
  if valid_593431 != nil:
    section.add "maxResults", valid_593431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593432 = header.getOrDefault("X-Amz-Signature")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Signature", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Content-Sha256", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Date")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Date", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Credential")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Credential", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-Security-Token")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Security-Token", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Algorithm")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Algorithm", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-SignedHeaders", valid_593438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593439: Call_ListBackupJobs_593406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about your backup jobs.
  ## 
  let valid = call_593439.validator(path, query, header, formData, body)
  let scheme = call_593439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593439.url(scheme.get, call_593439.host, call_593439.base,
                         call_593439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593439, url, valid)

proc call*(call_593440: Call_ListBackupJobs_593406; nextToken: string = "";
          backupVaultName: string = ""; MaxResults: string = "";
          state: string = "CREATED"; NextToken: string = ""; createdAfter: string = "";
          resourceType: string = ""; createdBefore: string = "";
          resourceArn: string = ""; maxResults: int = 0): Recallable =
  ## listBackupJobs
  ## Returns metadata about your backup jobs.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   backupVaultName: string
  ##                  : Returns only backup jobs that will be stored in the specified backup vault. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   state: string
  ##        : Returns only backup jobs that are in the specified state.
  ##   NextToken: string
  ##            : Pagination token
  ##   createdAfter: string
  ##               : Returns only backup jobs that were created after the specified date.
  ##   resourceType: string
  ##               : <p>Returns only backup jobs for the specified resources:</p> <ul> <li> <p> <code>EBS</code> for Amazon Elastic Block Store</p> </li> <li> <p> <code>SGW</code> for AWS Storage Gateway</p> </li> <li> <p> <code>RDS</code> for Amazon Relational Database Service</p> </li> <li> <p> <code>DDB</code> for Amazon DynamoDB</p> </li> <li> <p> <code>EFS</code> for Amazon Elastic File System</p> </li> </ul>
  ##   createdBefore: string
  ##                : Returns only backup jobs that were created before the specified date.
  ##   resourceArn: string
  ##              : Returns only backup jobs that match the specified resource Amazon Resource Name (ARN).
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_593441 = newJObject()
  add(query_593441, "nextToken", newJString(nextToken))
  add(query_593441, "backupVaultName", newJString(backupVaultName))
  add(query_593441, "MaxResults", newJString(MaxResults))
  add(query_593441, "state", newJString(state))
  add(query_593441, "NextToken", newJString(NextToken))
  add(query_593441, "createdAfter", newJString(createdAfter))
  add(query_593441, "resourceType", newJString(resourceType))
  add(query_593441, "createdBefore", newJString(createdBefore))
  add(query_593441, "resourceArn", newJString(resourceArn))
  add(query_593441, "maxResults", newJInt(maxResults))
  result = call_593440.call(nil, query_593441, nil, nil, nil)

var listBackupJobs* = Call_ListBackupJobs_593406(name: "listBackupJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup-jobs/",
    validator: validate_ListBackupJobs_593407, base: "/", url: url_ListBackupJobs_593408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanTemplates_593442 = ref object of OpenApiRestCall_592364
proc url_ListBackupPlanTemplates_593444(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBackupPlanTemplates_593443(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_593445 = query.getOrDefault("nextToken")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "nextToken", valid_593445
  var valid_593446 = query.getOrDefault("MaxResults")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "MaxResults", valid_593446
  var valid_593447 = query.getOrDefault("NextToken")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "NextToken", valid_593447
  var valid_593448 = query.getOrDefault("maxResults")
  valid_593448 = validateParameter(valid_593448, JInt, required = false, default = nil)
  if valid_593448 != nil:
    section.add "maxResults", valid_593448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593449 = header.getOrDefault("X-Amz-Signature")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Signature", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Content-Sha256", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Date")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Date", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Credential")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Credential", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Security-Token")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Security-Token", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Algorithm")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Algorithm", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-SignedHeaders", valid_593455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593456: Call_ListBackupPlanTemplates_593442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ## 
  let valid = call_593456.validator(path, query, header, formData, body)
  let scheme = call_593456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593456.url(scheme.get, call_593456.host, call_593456.base,
                         call_593456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593456, url, valid)

proc call*(call_593457: Call_ListBackupPlanTemplates_593442;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBackupPlanTemplates
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_593458 = newJObject()
  add(query_593458, "nextToken", newJString(nextToken))
  add(query_593458, "MaxResults", newJString(MaxResults))
  add(query_593458, "NextToken", newJString(NextToken))
  add(query_593458, "maxResults", newJInt(maxResults))
  result = call_593457.call(nil, query_593458, nil, nil, nil)

var listBackupPlanTemplates* = Call_ListBackupPlanTemplates_593442(
    name: "listBackupPlanTemplates", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/template/plans",
    validator: validate_ListBackupPlanTemplates_593443, base: "/",
    url: url_ListBackupPlanTemplates_593444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanVersions_593459 = ref object of OpenApiRestCall_592364
proc url_ListBackupPlanVersions_593461(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupPlanVersions_593460(path: JsonNode; query: JsonNode;
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
  var valid_593462 = path.getOrDefault("backupPlanId")
  valid_593462 = validateParameter(valid_593462, JString, required = true,
                                 default = nil)
  if valid_593462 != nil:
    section.add "backupPlanId", valid_593462
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_593463 = query.getOrDefault("nextToken")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "nextToken", valid_593463
  var valid_593464 = query.getOrDefault("MaxResults")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "MaxResults", valid_593464
  var valid_593465 = query.getOrDefault("NextToken")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "NextToken", valid_593465
  var valid_593466 = query.getOrDefault("maxResults")
  valid_593466 = validateParameter(valid_593466, JInt, required = false, default = nil)
  if valid_593466 != nil:
    section.add "maxResults", valid_593466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593467 = header.getOrDefault("X-Amz-Signature")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Signature", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-Content-Sha256", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-Date")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Date", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Credential")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Credential", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Security-Token")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Security-Token", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Algorithm")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Algorithm", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-SignedHeaders", valid_593473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593474: Call_ListBackupPlanVersions_593459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ## 
  let valid = call_593474.validator(path, query, header, formData, body)
  let scheme = call_593474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593474.url(scheme.get, call_593474.host, call_593474.base,
                         call_593474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593474, url, valid)

proc call*(call_593475: Call_ListBackupPlanVersions_593459; backupPlanId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBackupPlanVersions
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_593476 = newJObject()
  var query_593477 = newJObject()
  add(query_593477, "nextToken", newJString(nextToken))
  add(query_593477, "MaxResults", newJString(MaxResults))
  add(query_593477, "NextToken", newJString(NextToken))
  add(path_593476, "backupPlanId", newJString(backupPlanId))
  add(query_593477, "maxResults", newJInt(maxResults))
  result = call_593475.call(path_593476, query_593477, nil, nil, nil)

var listBackupPlanVersions* = Call_ListBackupPlanVersions_593459(
    name: "listBackupPlanVersions", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/plans/{backupPlanId}/versions/",
    validator: validate_ListBackupPlanVersions_593460, base: "/",
    url: url_ListBackupPlanVersions_593461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupVaults_593478 = ref object of OpenApiRestCall_592364
proc url_ListBackupVaults_593480(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBackupVaults_593479(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of recovery point storage containers along with information about them.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_593481 = query.getOrDefault("nextToken")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "nextToken", valid_593481
  var valid_593482 = query.getOrDefault("MaxResults")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "MaxResults", valid_593482
  var valid_593483 = query.getOrDefault("NextToken")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "NextToken", valid_593483
  var valid_593484 = query.getOrDefault("maxResults")
  valid_593484 = validateParameter(valid_593484, JInt, required = false, default = nil)
  if valid_593484 != nil:
    section.add "maxResults", valid_593484
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593485 = header.getOrDefault("X-Amz-Signature")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Signature", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Content-Sha256", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Date")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Date", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Credential")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Credential", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Security-Token")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Security-Token", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-Algorithm")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Algorithm", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-SignedHeaders", valid_593491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593492: Call_ListBackupVaults_593478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of recovery point storage containers along with information about them.
  ## 
  let valid = call_593492.validator(path, query, header, formData, body)
  let scheme = call_593492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593492.url(scheme.get, call_593492.host, call_593492.base,
                         call_593492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593492, url, valid)

proc call*(call_593493: Call_ListBackupVaults_593478; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listBackupVaults
  ## Returns a list of recovery point storage containers along with information about them.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_593494 = newJObject()
  add(query_593494, "nextToken", newJString(nextToken))
  add(query_593494, "MaxResults", newJString(MaxResults))
  add(query_593494, "NextToken", newJString(NextToken))
  add(query_593494, "maxResults", newJInt(maxResults))
  result = call_593493.call(nil, query_593494, nil, nil, nil)

var listBackupVaults* = Call_ListBackupVaults_593478(name: "listBackupVaults",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-vaults/", validator: validate_ListBackupVaults_593479,
    base: "/", url: url_ListBackupVaults_593480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProtectedResources_593495 = ref object of OpenApiRestCall_592364
proc url_ListProtectedResources_593497(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProtectedResources_593496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_593498 = query.getOrDefault("nextToken")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "nextToken", valid_593498
  var valid_593499 = query.getOrDefault("MaxResults")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "MaxResults", valid_593499
  var valid_593500 = query.getOrDefault("NextToken")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "NextToken", valid_593500
  var valid_593501 = query.getOrDefault("maxResults")
  valid_593501 = validateParameter(valid_593501, JInt, required = false, default = nil)
  if valid_593501 != nil:
    section.add "maxResults", valid_593501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593502 = header.getOrDefault("X-Amz-Signature")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Signature", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Content-Sha256", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Date")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Date", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-Credential")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Credential", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-Security-Token")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Security-Token", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-Algorithm")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-Algorithm", valid_593507
  var valid_593508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-SignedHeaders", valid_593508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593509: Call_ListProtectedResources_593495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ## 
  let valid = call_593509.validator(path, query, header, formData, body)
  let scheme = call_593509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593509.url(scheme.get, call_593509.host, call_593509.base,
                         call_593509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593509, url, valid)

proc call*(call_593510: Call_ListProtectedResources_593495; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listProtectedResources
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_593511 = newJObject()
  add(query_593511, "nextToken", newJString(nextToken))
  add(query_593511, "MaxResults", newJString(MaxResults))
  add(query_593511, "NextToken", newJString(NextToken))
  add(query_593511, "maxResults", newJInt(maxResults))
  result = call_593510.call(nil, query_593511, nil, nil, nil)

var listProtectedResources* = Call_ListProtectedResources_593495(
    name: "listProtectedResources", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/",
    validator: validate_ListProtectedResources_593496, base: "/",
    url: url_ListProtectedResources_593497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByBackupVault_593512 = ref object of OpenApiRestCall_592364
proc url_ListRecoveryPointsByBackupVault_593514(protocol: Scheme; host: string;
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

proc validate_ListRecoveryPointsByBackupVault_593513(path: JsonNode;
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
  var valid_593515 = path.getOrDefault("backupVaultName")
  valid_593515 = validateParameter(valid_593515, JString, required = true,
                                 default = nil)
  if valid_593515 != nil:
    section.add "backupVaultName", valid_593515
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   backupPlanId: JString
  ##               : Returns only recovery points that match the specified backup plan ID.
  ##   NextToken: JString
  ##            : Pagination token
  ##   createdAfter: JString
  ##               : Returns only recovery points that were created after the specified timestamp.
  ##   resourceType: JString
  ##               : Returns only recovery points that match the specified resource type.
  ##   createdBefore: JString
  ##                : Returns only recovery points that were created before the specified timestamp.
  ##   resourceArn: JString
  ##              : Returns only recovery points that match the specified resource Amazon Resource Name (ARN).
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_593516 = query.getOrDefault("nextToken")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "nextToken", valid_593516
  var valid_593517 = query.getOrDefault("MaxResults")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "MaxResults", valid_593517
  var valid_593518 = query.getOrDefault("backupPlanId")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "backupPlanId", valid_593518
  var valid_593519 = query.getOrDefault("NextToken")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "NextToken", valid_593519
  var valid_593520 = query.getOrDefault("createdAfter")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "createdAfter", valid_593520
  var valid_593521 = query.getOrDefault("resourceType")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "resourceType", valid_593521
  var valid_593522 = query.getOrDefault("createdBefore")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "createdBefore", valid_593522
  var valid_593523 = query.getOrDefault("resourceArn")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "resourceArn", valid_593523
  var valid_593524 = query.getOrDefault("maxResults")
  valid_593524 = validateParameter(valid_593524, JInt, required = false, default = nil)
  if valid_593524 != nil:
    section.add "maxResults", valid_593524
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593525 = header.getOrDefault("X-Amz-Signature")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Signature", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-Content-Sha256", valid_593526
  var valid_593527 = header.getOrDefault("X-Amz-Date")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "X-Amz-Date", valid_593527
  var valid_593528 = header.getOrDefault("X-Amz-Credential")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "X-Amz-Credential", valid_593528
  var valid_593529 = header.getOrDefault("X-Amz-Security-Token")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "X-Amz-Security-Token", valid_593529
  var valid_593530 = header.getOrDefault("X-Amz-Algorithm")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "X-Amz-Algorithm", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-SignedHeaders", valid_593531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593532: Call_ListRecoveryPointsByBackupVault_593512;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns detailed information about the recovery points stored in a backup vault.
  ## 
  let valid = call_593532.validator(path, query, header, formData, body)
  let scheme = call_593532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593532.url(scheme.get, call_593532.host, call_593532.base,
                         call_593532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593532, url, valid)

proc call*(call_593533: Call_ListRecoveryPointsByBackupVault_593512;
          backupVaultName: string; nextToken: string = ""; MaxResults: string = "";
          backupPlanId: string = ""; NextToken: string = ""; createdAfter: string = "";
          resourceType: string = ""; createdBefore: string = "";
          resourceArn: string = ""; maxResults: int = 0): Recallable =
  ## listRecoveryPointsByBackupVault
  ## Returns detailed information about the recovery points stored in a backup vault.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   backupPlanId: string
  ##               : Returns only recovery points that match the specified backup plan ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   createdAfter: string
  ##               : Returns only recovery points that were created after the specified timestamp.
  ##   resourceType: string
  ##               : Returns only recovery points that match the specified resource type.
  ##   createdBefore: string
  ##                : Returns only recovery points that were created before the specified timestamp.
  ##   resourceArn: string
  ##              : Returns only recovery points that match the specified resource Amazon Resource Name (ARN).
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_593534 = newJObject()
  var query_593535 = newJObject()
  add(query_593535, "nextToken", newJString(nextToken))
  add(query_593535, "MaxResults", newJString(MaxResults))
  add(path_593534, "backupVaultName", newJString(backupVaultName))
  add(query_593535, "backupPlanId", newJString(backupPlanId))
  add(query_593535, "NextToken", newJString(NextToken))
  add(query_593535, "createdAfter", newJString(createdAfter))
  add(query_593535, "resourceType", newJString(resourceType))
  add(query_593535, "createdBefore", newJString(createdBefore))
  add(query_593535, "resourceArn", newJString(resourceArn))
  add(query_593535, "maxResults", newJInt(maxResults))
  result = call_593533.call(path_593534, query_593535, nil, nil, nil)

var listRecoveryPointsByBackupVault* = Call_ListRecoveryPointsByBackupVault_593512(
    name: "listRecoveryPointsByBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/recovery-points/",
    validator: validate_ListRecoveryPointsByBackupVault_593513, base: "/",
    url: url_ListRecoveryPointsByBackupVault_593514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByResource_593536 = ref object of OpenApiRestCall_592364
proc url_ListRecoveryPointsByResource_593538(protocol: Scheme; host: string;
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

proc validate_ListRecoveryPointsByResource_593537(path: JsonNode; query: JsonNode;
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
  var valid_593539 = path.getOrDefault("resourceArn")
  valid_593539 = validateParameter(valid_593539, JString, required = true,
                                 default = nil)
  if valid_593539 != nil:
    section.add "resourceArn", valid_593539
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_593540 = query.getOrDefault("nextToken")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "nextToken", valid_593540
  var valid_593541 = query.getOrDefault("MaxResults")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "MaxResults", valid_593541
  var valid_593542 = query.getOrDefault("NextToken")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "NextToken", valid_593542
  var valid_593543 = query.getOrDefault("maxResults")
  valid_593543 = validateParameter(valid_593543, JInt, required = false, default = nil)
  if valid_593543 != nil:
    section.add "maxResults", valid_593543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593544 = header.getOrDefault("X-Amz-Signature")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Signature", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-Content-Sha256", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-Date")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-Date", valid_593546
  var valid_593547 = header.getOrDefault("X-Amz-Credential")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Credential", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Security-Token")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Security-Token", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Algorithm")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Algorithm", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-SignedHeaders", valid_593550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593551: Call_ListRecoveryPointsByResource_593536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ## 
  let valid = call_593551.validator(path, query, header, formData, body)
  let scheme = call_593551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593551.url(scheme.get, call_593551.host, call_593551.base,
                         call_593551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593551, url, valid)

proc call*(call_593552: Call_ListRecoveryPointsByResource_593536;
          resourceArn: string; nextToken: string = ""; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listRecoveryPointsByResource
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the resource type.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_593553 = newJObject()
  var query_593554 = newJObject()
  add(query_593554, "nextToken", newJString(nextToken))
  add(query_593554, "MaxResults", newJString(MaxResults))
  add(path_593553, "resourceArn", newJString(resourceArn))
  add(query_593554, "NextToken", newJString(NextToken))
  add(query_593554, "maxResults", newJInt(maxResults))
  result = call_593552.call(path_593553, query_593554, nil, nil, nil)

var listRecoveryPointsByResource* = Call_ListRecoveryPointsByResource_593536(
    name: "listRecoveryPointsByResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/resources/{resourceArn}/recovery-points/",
    validator: validate_ListRecoveryPointsByResource_593537, base: "/",
    url: url_ListRecoveryPointsByResource_593538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRestoreJobs_593555 = ref object of OpenApiRestCall_592364
proc url_ListRestoreJobs_593557(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRestoreJobs_593556(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_593558 = query.getOrDefault("nextToken")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "nextToken", valid_593558
  var valid_593559 = query.getOrDefault("MaxResults")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "MaxResults", valid_593559
  var valid_593560 = query.getOrDefault("NextToken")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "NextToken", valid_593560
  var valid_593561 = query.getOrDefault("maxResults")
  valid_593561 = validateParameter(valid_593561, JInt, required = false, default = nil)
  if valid_593561 != nil:
    section.add "maxResults", valid_593561
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593562 = header.getOrDefault("X-Amz-Signature")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Signature", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Content-Sha256", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-Date")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-Date", valid_593564
  var valid_593565 = header.getOrDefault("X-Amz-Credential")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-Credential", valid_593565
  var valid_593566 = header.getOrDefault("X-Amz-Security-Token")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Security-Token", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-Algorithm")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Algorithm", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-SignedHeaders", valid_593568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593569: Call_ListRestoreJobs_593555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ## 
  let valid = call_593569.validator(path, query, header, formData, body)
  let scheme = call_593569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593569.url(scheme.get, call_593569.host, call_593569.base,
                         call_593569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593569, url, valid)

proc call*(call_593570: Call_ListRestoreJobs_593555; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listRestoreJobs
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_593571 = newJObject()
  add(query_593571, "nextToken", newJString(nextToken))
  add(query_593571, "MaxResults", newJString(MaxResults))
  add(query_593571, "NextToken", newJString(NextToken))
  add(query_593571, "maxResults", newJInt(maxResults))
  result = call_593570.call(nil, query_593571, nil, nil, nil)

var listRestoreJobs* = Call_ListRestoreJobs_593555(name: "listRestoreJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/restore-jobs/",
    validator: validate_ListRestoreJobs_593556, base: "/", url: url_ListRestoreJobs_593557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_593572 = ref object of OpenApiRestCall_592364
proc url_ListTags_593574(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_593573(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593575 = path.getOrDefault("resourceArn")
  valid_593575 = validateParameter(valid_593575, JString, required = true,
                                 default = nil)
  if valid_593575 != nil:
    section.add "resourceArn", valid_593575
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_593576 = query.getOrDefault("nextToken")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "nextToken", valid_593576
  var valid_593577 = query.getOrDefault("MaxResults")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "MaxResults", valid_593577
  var valid_593578 = query.getOrDefault("NextToken")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "NextToken", valid_593578
  var valid_593579 = query.getOrDefault("maxResults")
  valid_593579 = validateParameter(valid_593579, JInt, required = false, default = nil)
  if valid_593579 != nil:
    section.add "maxResults", valid_593579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593580 = header.getOrDefault("X-Amz-Signature")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-Signature", valid_593580
  var valid_593581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Content-Sha256", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-Date")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-Date", valid_593582
  var valid_593583 = header.getOrDefault("X-Amz-Credential")
  valid_593583 = validateParameter(valid_593583, JString, required = false,
                                 default = nil)
  if valid_593583 != nil:
    section.add "X-Amz-Credential", valid_593583
  var valid_593584 = header.getOrDefault("X-Amz-Security-Token")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Security-Token", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-Algorithm")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-Algorithm", valid_593585
  var valid_593586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "X-Amz-SignedHeaders", valid_593586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593587: Call_ListTags_593572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ## 
  let valid = call_593587.validator(path, query, header, formData, body)
  let scheme = call_593587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593587.url(scheme.get, call_593587.host, call_593587.base,
                         call_593587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593587, url, valid)

proc call*(call_593588: Call_ListTags_593572; resourceArn: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listTags
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the type of resource. Valid targets for <code>ListTags</code> are recovery points, backup plans, and backup vaults.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_593589 = newJObject()
  var query_593590 = newJObject()
  add(query_593590, "nextToken", newJString(nextToken))
  add(query_593590, "MaxResults", newJString(MaxResults))
  add(path_593589, "resourceArn", newJString(resourceArn))
  add(query_593590, "NextToken", newJString(NextToken))
  add(query_593590, "maxResults", newJInt(maxResults))
  result = call_593588.call(path_593589, query_593590, nil, nil, nil)

var listTags* = Call_ListTags_593572(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "backup.amazonaws.com",
                                  route: "/tags/{resourceArn}/",
                                  validator: validate_ListTags_593573, base: "/",
                                  url: url_ListTags_593574,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBackupJob_593591 = ref object of OpenApiRestCall_592364
proc url_StartBackupJob_593593(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartBackupJob_593592(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593594 = header.getOrDefault("X-Amz-Signature")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Signature", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-Content-Sha256", valid_593595
  var valid_593596 = header.getOrDefault("X-Amz-Date")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Date", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-Credential")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-Credential", valid_593597
  var valid_593598 = header.getOrDefault("X-Amz-Security-Token")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = nil)
  if valid_593598 != nil:
    section.add "X-Amz-Security-Token", valid_593598
  var valid_593599 = header.getOrDefault("X-Amz-Algorithm")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Algorithm", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-SignedHeaders", valid_593600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593602: Call_StartBackupJob_593591; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to create a one-time backup of the specified resource.
  ## 
  let valid = call_593602.validator(path, query, header, formData, body)
  let scheme = call_593602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593602.url(scheme.get, call_593602.host, call_593602.base,
                         call_593602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593602, url, valid)

proc call*(call_593603: Call_StartBackupJob_593591; body: JsonNode): Recallable =
  ## startBackupJob
  ## Starts a job to create a one-time backup of the specified resource.
  ##   body: JObject (required)
  var body_593604 = newJObject()
  if body != nil:
    body_593604 = body
  result = call_593603.call(nil, nil, nil, nil, body_593604)

var startBackupJob* = Call_StartBackupJob_593591(name: "startBackupJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup-jobs",
    validator: validate_StartBackupJob_593592, base: "/", url: url_StartBackupJob_593593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRestoreJob_593605 = ref object of OpenApiRestCall_592364
proc url_StartRestoreJob_593607(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartRestoreJob_593606(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593608 = header.getOrDefault("X-Amz-Signature")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Signature", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-Content-Sha256", valid_593609
  var valid_593610 = header.getOrDefault("X-Amz-Date")
  valid_593610 = validateParameter(valid_593610, JString, required = false,
                                 default = nil)
  if valid_593610 != nil:
    section.add "X-Amz-Date", valid_593610
  var valid_593611 = header.getOrDefault("X-Amz-Credential")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "X-Amz-Credential", valid_593611
  var valid_593612 = header.getOrDefault("X-Amz-Security-Token")
  valid_593612 = validateParameter(valid_593612, JString, required = false,
                                 default = nil)
  if valid_593612 != nil:
    section.add "X-Amz-Security-Token", valid_593612
  var valid_593613 = header.getOrDefault("X-Amz-Algorithm")
  valid_593613 = validateParameter(valid_593613, JString, required = false,
                                 default = nil)
  if valid_593613 != nil:
    section.add "X-Amz-Algorithm", valid_593613
  var valid_593614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593614 = validateParameter(valid_593614, JString, required = false,
                                 default = nil)
  if valid_593614 != nil:
    section.add "X-Amz-SignedHeaders", valid_593614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593616: Call_StartRestoreJob_593605; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ## 
  let valid = call_593616.validator(path, query, header, formData, body)
  let scheme = call_593616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593616.url(scheme.get, call_593616.host, call_593616.base,
                         call_593616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593616, url, valid)

proc call*(call_593617: Call_StartRestoreJob_593605; body: JsonNode): Recallable =
  ## startRestoreJob
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ##   body: JObject (required)
  var body_593618 = newJObject()
  if body != nil:
    body_593618 = body
  result = call_593617.call(nil, nil, nil, nil, body_593618)

var startRestoreJob* = Call_StartRestoreJob_593605(name: "startRestoreJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/restore-jobs",
    validator: validate_StartRestoreJob_593606, base: "/", url: url_StartRestoreJob_593607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593619 = ref object of OpenApiRestCall_592364
proc url_TagResource_593621(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_593620(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593622 = path.getOrDefault("resourceArn")
  valid_593622 = validateParameter(valid_593622, JString, required = true,
                                 default = nil)
  if valid_593622 != nil:
    section.add "resourceArn", valid_593622
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593623 = header.getOrDefault("X-Amz-Signature")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Signature", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Content-Sha256", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Date")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Date", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Credential")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Credential", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-Security-Token")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-Security-Token", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-Algorithm")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-Algorithm", valid_593628
  var valid_593629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = nil)
  if valid_593629 != nil:
    section.add "X-Amz-SignedHeaders", valid_593629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593631: Call_TagResource_593619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ## 
  let valid = call_593631.validator(path, query, header, formData, body)
  let scheme = call_593631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593631.url(scheme.get, call_593631.host, call_593631.base,
                         call_593631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593631, url, valid)

proc call*(call_593632: Call_TagResource_593619; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  ##   body: JObject (required)
  var path_593633 = newJObject()
  var body_593634 = newJObject()
  add(path_593633, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_593634 = body
  result = call_593632.call(path_593633, nil, nil, nil, body_593634)

var tagResource* = Call_TagResource_593619(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "backup.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_593620,
                                        base: "/", url: url_TagResource_593621,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593635 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593637(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_593636(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593638 = path.getOrDefault("resourceArn")
  valid_593638 = validateParameter(valid_593638, JString, required = true,
                                 default = nil)
  if valid_593638 != nil:
    section.add "resourceArn", valid_593638
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593639 = header.getOrDefault("X-Amz-Signature")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Signature", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Content-Sha256", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Date")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Date", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-Credential")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Credential", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Security-Token")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Security-Token", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-Algorithm")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-Algorithm", valid_593644
  var valid_593645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593645 = validateParameter(valid_593645, JString, required = false,
                                 default = nil)
  if valid_593645 != nil:
    section.add "X-Amz-SignedHeaders", valid_593645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593647: Call_UntagResource_593635; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ## 
  let valid = call_593647.validator(path, query, header, formData, body)
  let scheme = call_593647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593647.url(scheme.get, call_593647.host, call_593647.base,
                         call_593647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593647, url, valid)

proc call*(call_593648: Call_UntagResource_593635; resourceArn: string;
          body: JsonNode): Recallable =
  ## untagResource
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  ##   body: JObject (required)
  var path_593649 = newJObject()
  var body_593650 = newJObject()
  add(path_593649, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_593650 = body
  result = call_593648.call(path_593649, nil, nil, nil, body_593650)

var untagResource* = Call_UntagResource_593635(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/untag/{resourceArn}", validator: validate_UntagResource_593636,
    base: "/", url: url_UntagResource_593637, schemes: {Scheme.Https, Scheme.Http})
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
