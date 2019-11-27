
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateBackupPlan_599965 = ref object of OpenApiRestCall_599368
proc url_CreateBackupPlan_599967(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBackupPlan_599966(path: JsonNode; query: JsonNode;
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
  var valid_599968 = header.getOrDefault("X-Amz-Date")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Date", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Security-Token")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Security-Token", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Content-Sha256", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Algorithm")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Algorithm", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Signature")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Signature", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-SignedHeaders", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-Credential")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-Credential", valid_599974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599976: Call_CreateBackupPlan_599965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, the existing <code>backupPlanId</code> is returned.</p>
  ## 
  let valid = call_599976.validator(path, query, header, formData, body)
  let scheme = call_599976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599976.url(scheme.get, call_599976.host, call_599976.base,
                         call_599976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599976, url, valid)

proc call*(call_599977: Call_CreateBackupPlan_599965; body: JsonNode): Recallable =
  ## createBackupPlan
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, the existing <code>backupPlanId</code> is returned.</p>
  ##   body: JObject (required)
  var body_599978 = newJObject()
  if body != nil:
    body_599978 = body
  result = call_599977.call(nil, nil, nil, nil, body_599978)

var createBackupPlan* = Call_CreateBackupPlan_599965(name: "createBackupPlan",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_CreateBackupPlan_599966, base: "/",
    url: url_CreateBackupPlan_599967, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlans_599705 = ref object of OpenApiRestCall_599368
proc url_ListBackupPlans_599707(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBackupPlans_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = query.getOrDefault("NextToken")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "NextToken", valid_599819
  var valid_599820 = query.getOrDefault("maxResults")
  valid_599820 = validateParameter(valid_599820, JInt, required = false, default = nil)
  if valid_599820 != nil:
    section.add "maxResults", valid_599820
  var valid_599821 = query.getOrDefault("nextToken")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "nextToken", valid_599821
  var valid_599822 = query.getOrDefault("includeDeleted")
  valid_599822 = validateParameter(valid_599822, JBool, required = false, default = nil)
  if valid_599822 != nil:
    section.add "includeDeleted", valid_599822
  var valid_599823 = query.getOrDefault("MaxResults")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "MaxResults", valid_599823
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
  var valid_599824 = header.getOrDefault("X-Amz-Date")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Date", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Security-Token")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Security-Token", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Content-Sha256", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Algorithm")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Algorithm", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Signature")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Signature", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-SignedHeaders", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-Credential")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-Credential", valid_599830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599853: Call_ListBackupPlans_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ## 
  let valid = call_599853.validator(path, query, header, formData, body)
  let scheme = call_599853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599853.url(scheme.get, call_599853.host, call_599853.base,
                         call_599853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599853, url, valid)

proc call*(call_599924: Call_ListBackupPlans_599705; NextToken: string = "";
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
  var query_599925 = newJObject()
  add(query_599925, "NextToken", newJString(NextToken))
  add(query_599925, "maxResults", newJInt(maxResults))
  add(query_599925, "nextToken", newJString(nextToken))
  add(query_599925, "includeDeleted", newJBool(includeDeleted))
  add(query_599925, "MaxResults", newJString(MaxResults))
  result = call_599924.call(nil, query_599925, nil, nil, nil)

var listBackupPlans* = Call_ListBackupPlans_599705(name: "listBackupPlans",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_ListBackupPlans_599706, base: "/", url: url_ListBackupPlans_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupSelection_600012 = ref object of OpenApiRestCall_599368
proc url_CreateBackupSelection_600014(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBackupSelection_600013(path: JsonNode; query: JsonNode;
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
  var valid_600015 = path.getOrDefault("backupPlanId")
  valid_600015 = validateParameter(valid_600015, JString, required = true,
                                 default = nil)
  if valid_600015 != nil:
    section.add "backupPlanId", valid_600015
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
  var valid_600016 = header.getOrDefault("X-Amz-Date")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Date", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Security-Token")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Security-Token", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Content-Sha256", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Algorithm")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Algorithm", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Signature")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Signature", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-SignedHeaders", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Credential")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Credential", valid_600022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600024: Call_CreateBackupSelection_600012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ## 
  let valid = call_600024.validator(path, query, header, formData, body)
  let scheme = call_600024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600024.url(scheme.get, call_600024.host, call_600024.base,
                         call_600024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600024, url, valid)

proc call*(call_600025: Call_CreateBackupSelection_600012; backupPlanId: string;
          body: JsonNode): Recallable =
  ## createBackupSelection
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"StringEquals"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies the backup plan to be associated with the selection of resources.
  ##   body: JObject (required)
  var path_600026 = newJObject()
  var body_600027 = newJObject()
  add(path_600026, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_600027 = body
  result = call_600025.call(path_600026, nil, nil, nil, body_600027)

var createBackupSelection* = Call_CreateBackupSelection_600012(
    name: "createBackupSelection", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_CreateBackupSelection_600013, base: "/",
    url: url_CreateBackupSelection_600014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupSelections_599979 = ref object of OpenApiRestCall_599368
proc url_ListBackupSelections_599981(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBackupSelections_599980(path: JsonNode; query: JsonNode;
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
  var valid_599996 = path.getOrDefault("backupPlanId")
  valid_599996 = validateParameter(valid_599996, JString, required = true,
                                 default = nil)
  if valid_599996 != nil:
    section.add "backupPlanId", valid_599996
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
  var valid_599997 = query.getOrDefault("NextToken")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "NextToken", valid_599997
  var valid_599998 = query.getOrDefault("maxResults")
  valid_599998 = validateParameter(valid_599998, JInt, required = false, default = nil)
  if valid_599998 != nil:
    section.add "maxResults", valid_599998
  var valid_599999 = query.getOrDefault("nextToken")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "nextToken", valid_599999
  var valid_600000 = query.getOrDefault("MaxResults")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "MaxResults", valid_600000
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
  var valid_600001 = header.getOrDefault("X-Amz-Date")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Date", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Security-Token")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Security-Token", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Content-Sha256", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Algorithm")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Algorithm", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Signature")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Signature", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-SignedHeaders", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Credential")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Credential", valid_600007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600008: Call_ListBackupSelections_599979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ## 
  let valid = call_600008.validator(path, query, header, formData, body)
  let scheme = call_600008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600008.url(scheme.get, call_600008.host, call_600008.base,
                         call_600008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600008, url, valid)

proc call*(call_600009: Call_ListBackupSelections_599979; backupPlanId: string;
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
  var path_600010 = newJObject()
  var query_600011 = newJObject()
  add(path_600010, "backupPlanId", newJString(backupPlanId))
  add(query_600011, "NextToken", newJString(NextToken))
  add(query_600011, "maxResults", newJInt(maxResults))
  add(query_600011, "nextToken", newJString(nextToken))
  add(query_600011, "MaxResults", newJString(MaxResults))
  result = call_600009.call(path_600010, query_600011, nil, nil, nil)

var listBackupSelections* = Call_ListBackupSelections_599979(
    name: "listBackupSelections", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_ListBackupSelections_599980, base: "/",
    url: url_ListBackupSelections_599981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupVault_600042 = ref object of OpenApiRestCall_599368
proc url_CreateBackupVault_600044(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBackupVault_600043(path: JsonNode; query: JsonNode;
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
  var valid_600045 = path.getOrDefault("backupVaultName")
  valid_600045 = validateParameter(valid_600045, JString, required = true,
                                 default = nil)
  if valid_600045 != nil:
    section.add "backupVaultName", valid_600045
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
  var valid_600046 = header.getOrDefault("X-Amz-Date")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Date", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Security-Token")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Security-Token", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Content-Sha256", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Algorithm")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Algorithm", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Signature")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Signature", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-SignedHeaders", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Credential")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Credential", valid_600052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600054: Call_CreateBackupVault_600042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ## 
  let valid = call_600054.validator(path, query, header, formData, body)
  let scheme = call_600054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600054.url(scheme.get, call_600054.host, call_600054.base,
                         call_600054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600054, url, valid)

proc call*(call_600055: Call_CreateBackupVault_600042; backupVaultName: string;
          body: JsonNode): Recallable =
  ## createBackupVault
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_600056 = newJObject()
  var body_600057 = newJObject()
  add(path_600056, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_600057 = body
  result = call_600055.call(path_600056, nil, nil, nil, body_600057)

var createBackupVault* = Call_CreateBackupVault_600042(name: "createBackupVault",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_CreateBackupVault_600043, base: "/",
    url: url_CreateBackupVault_600044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupVault_600028 = ref object of OpenApiRestCall_599368
proc url_DescribeBackupVault_600030(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBackupVault_600029(path: JsonNode; query: JsonNode;
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
  var valid_600031 = path.getOrDefault("backupVaultName")
  valid_600031 = validateParameter(valid_600031, JString, required = true,
                                 default = nil)
  if valid_600031 != nil:
    section.add "backupVaultName", valid_600031
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
  var valid_600032 = header.getOrDefault("X-Amz-Date")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Date", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Security-Token")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Security-Token", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Content-Sha256", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Algorithm")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Algorithm", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Signature")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Signature", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-SignedHeaders", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Credential")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Credential", valid_600038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600039: Call_DescribeBackupVault_600028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a backup vault specified by its name.
  ## 
  let valid = call_600039.validator(path, query, header, formData, body)
  let scheme = call_600039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600039.url(scheme.get, call_600039.host, call_600039.base,
                         call_600039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600039, url, valid)

proc call*(call_600040: Call_DescribeBackupVault_600028; backupVaultName: string): Recallable =
  ## describeBackupVault
  ## Returns metadata about a backup vault specified by its name.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_600041 = newJObject()
  add(path_600041, "backupVaultName", newJString(backupVaultName))
  result = call_600040.call(path_600041, nil, nil, nil, nil)

var describeBackupVault* = Call_DescribeBackupVault_600028(
    name: "describeBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}",
    validator: validate_DescribeBackupVault_600029, base: "/",
    url: url_DescribeBackupVault_600030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVault_600058 = ref object of OpenApiRestCall_599368
proc url_DeleteBackupVault_600060(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupVault_600059(path: JsonNode; query: JsonNode;
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
  var valid_600061 = path.getOrDefault("backupVaultName")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = nil)
  if valid_600061 != nil:
    section.add "backupVaultName", valid_600061
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
  var valid_600062 = header.getOrDefault("X-Amz-Date")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Date", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Security-Token")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Security-Token", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Content-Sha256", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Algorithm")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Algorithm", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Signature")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Signature", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-SignedHeaders", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Credential")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Credential", valid_600068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600069: Call_DeleteBackupVault_600058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ## 
  let valid = call_600069.validator(path, query, header, formData, body)
  let scheme = call_600069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600069.url(scheme.get, call_600069.host, call_600069.base,
                         call_600069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600069, url, valid)

proc call*(call_600070: Call_DeleteBackupVault_600058; backupVaultName: string): Recallable =
  ## deleteBackupVault
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and theAWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_600071 = newJObject()
  add(path_600071, "backupVaultName", newJString(backupVaultName))
  result = call_600070.call(path_600071, nil, nil, nil, nil)

var deleteBackupVault* = Call_DeleteBackupVault_600058(name: "deleteBackupVault",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_DeleteBackupVault_600059, base: "/",
    url: url_DeleteBackupVault_600060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBackupPlan_600072 = ref object of OpenApiRestCall_599368
proc url_UpdateBackupPlan_600074(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBackupPlan_600073(path: JsonNode; query: JsonNode;
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
  var valid_600075 = path.getOrDefault("backupPlanId")
  valid_600075 = validateParameter(valid_600075, JString, required = true,
                                 default = nil)
  if valid_600075 != nil:
    section.add "backupPlanId", valid_600075
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
  var valid_600076 = header.getOrDefault("X-Amz-Date")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Date", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Security-Token")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Security-Token", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Content-Sha256", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Algorithm")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Algorithm", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Signature")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Signature", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-SignedHeaders", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Credential")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Credential", valid_600082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600084: Call_UpdateBackupPlan_600072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ## 
  let valid = call_600084.validator(path, query, header, formData, body)
  let scheme = call_600084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600084.url(scheme.get, call_600084.host, call_600084.base,
                         call_600084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600084, url, valid)

proc call*(call_600085: Call_UpdateBackupPlan_600072; backupPlanId: string;
          body: JsonNode): Recallable =
  ## updateBackupPlan
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   body: JObject (required)
  var path_600086 = newJObject()
  var body_600087 = newJObject()
  add(path_600086, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_600087 = body
  result = call_600085.call(path_600086, nil, nil, nil, body_600087)

var updateBackupPlan* = Call_UpdateBackupPlan_600072(name: "updateBackupPlan",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_UpdateBackupPlan_600073,
    base: "/", url: url_UpdateBackupPlan_600074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupPlan_600088 = ref object of OpenApiRestCall_599368
proc url_DeleteBackupPlan_600090(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupPlan_600089(path: JsonNode; query: JsonNode;
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
  var valid_600091 = path.getOrDefault("backupPlanId")
  valid_600091 = validateParameter(valid_600091, JString, required = true,
                                 default = nil)
  if valid_600091 != nil:
    section.add "backupPlanId", valid_600091
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
  var valid_600092 = header.getOrDefault("X-Amz-Date")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Date", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Security-Token")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Security-Token", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Content-Sha256", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-Algorithm")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Algorithm", valid_600095
  var valid_600096 = header.getOrDefault("X-Amz-Signature")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Signature", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-SignedHeaders", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Credential")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Credential", valid_600098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600099: Call_DeleteBackupPlan_600088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ## 
  let valid = call_600099.validator(path, query, header, formData, body)
  let scheme = call_600099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600099.url(scheme.get, call_600099.host, call_600099.base,
                         call_600099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600099, url, valid)

proc call*(call_600100: Call_DeleteBackupPlan_600088; backupPlanId: string): Recallable =
  ## deleteBackupPlan
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_600101 = newJObject()
  add(path_600101, "backupPlanId", newJString(backupPlanId))
  result = call_600100.call(path_600101, nil, nil, nil, nil)

var deleteBackupPlan* = Call_DeleteBackupPlan_600088(name: "deleteBackupPlan",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_DeleteBackupPlan_600089,
    base: "/", url: url_DeleteBackupPlan_600090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupSelection_600102 = ref object of OpenApiRestCall_599368
proc url_GetBackupSelection_600104(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupSelection_600103(path: JsonNode; query: JsonNode;
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
  var valid_600105 = path.getOrDefault("backupPlanId")
  valid_600105 = validateParameter(valid_600105, JString, required = true,
                                 default = nil)
  if valid_600105 != nil:
    section.add "backupPlanId", valid_600105
  var valid_600106 = path.getOrDefault("selectionId")
  valid_600106 = validateParameter(valid_600106, JString, required = true,
                                 default = nil)
  if valid_600106 != nil:
    section.add "selectionId", valid_600106
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
  var valid_600107 = header.getOrDefault("X-Amz-Date")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Date", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Security-Token")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Security-Token", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Content-Sha256", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Algorithm")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Algorithm", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Signature")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Signature", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-SignedHeaders", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Credential")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Credential", valid_600113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600114: Call_GetBackupSelection_600102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ## 
  let valid = call_600114.validator(path, query, header, formData, body)
  let scheme = call_600114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600114.url(scheme.get, call_600114.host, call_600114.base,
                         call_600114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600114, url, valid)

proc call*(call_600115: Call_GetBackupSelection_600102; backupPlanId: string;
          selectionId: string): Recallable =
  ## getBackupSelection
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_600116 = newJObject()
  add(path_600116, "backupPlanId", newJString(backupPlanId))
  add(path_600116, "selectionId", newJString(selectionId))
  result = call_600115.call(path_600116, nil, nil, nil, nil)

var getBackupSelection* = Call_GetBackupSelection_600102(
    name: "getBackupSelection", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_GetBackupSelection_600103, base: "/",
    url: url_GetBackupSelection_600104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupSelection_600117 = ref object of OpenApiRestCall_599368
proc url_DeleteBackupSelection_600119(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupSelection_600118(path: JsonNode; query: JsonNode;
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
  var valid_600120 = path.getOrDefault("backupPlanId")
  valid_600120 = validateParameter(valid_600120, JString, required = true,
                                 default = nil)
  if valid_600120 != nil:
    section.add "backupPlanId", valid_600120
  var valid_600121 = path.getOrDefault("selectionId")
  valid_600121 = validateParameter(valid_600121, JString, required = true,
                                 default = nil)
  if valid_600121 != nil:
    section.add "selectionId", valid_600121
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
  var valid_600122 = header.getOrDefault("X-Amz-Date")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Date", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Security-Token")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Security-Token", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Content-Sha256", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Algorithm")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Algorithm", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Signature")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Signature", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-SignedHeaders", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Credential")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Credential", valid_600128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600129: Call_DeleteBackupSelection_600117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ## 
  let valid = call_600129.validator(path, query, header, formData, body)
  let scheme = call_600129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600129.url(scheme.get, call_600129.host, call_600129.base,
                         call_600129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600129, url, valid)

proc call*(call_600130: Call_DeleteBackupSelection_600117; backupPlanId: string;
          selectionId: string): Recallable =
  ## deleteBackupSelection
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_600131 = newJObject()
  add(path_600131, "backupPlanId", newJString(backupPlanId))
  add(path_600131, "selectionId", newJString(selectionId))
  result = call_600130.call(path_600131, nil, nil, nil, nil)

var deleteBackupSelection* = Call_DeleteBackupSelection_600117(
    name: "deleteBackupSelection", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_DeleteBackupSelection_600118, base: "/",
    url: url_DeleteBackupSelection_600119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultAccessPolicy_600146 = ref object of OpenApiRestCall_599368
proc url_PutBackupVaultAccessPolicy_600148(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBackupVaultAccessPolicy_600147(path: JsonNode; query: JsonNode;
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
  var valid_600149 = path.getOrDefault("backupVaultName")
  valid_600149 = validateParameter(valid_600149, JString, required = true,
                                 default = nil)
  if valid_600149 != nil:
    section.add "backupVaultName", valid_600149
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
  var valid_600150 = header.getOrDefault("X-Amz-Date")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Date", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Security-Token")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Security-Token", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Content-Sha256", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Algorithm")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Algorithm", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Signature")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Signature", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-SignedHeaders", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Credential")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Credential", valid_600156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600158: Call_PutBackupVaultAccessPolicy_600146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ## 
  let valid = call_600158.validator(path, query, header, formData, body)
  let scheme = call_600158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600158.url(scheme.get, call_600158.host, call_600158.base,
                         call_600158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600158, url, valid)

proc call*(call_600159: Call_PutBackupVaultAccessPolicy_600146;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultAccessPolicy
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_600160 = newJObject()
  var body_600161 = newJObject()
  add(path_600160, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_600161 = body
  result = call_600159.call(path_600160, nil, nil, nil, body_600161)

var putBackupVaultAccessPolicy* = Call_PutBackupVaultAccessPolicy_600146(
    name: "putBackupVaultAccessPolicy", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_PutBackupVaultAccessPolicy_600147, base: "/",
    url: url_PutBackupVaultAccessPolicy_600148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultAccessPolicy_600132 = ref object of OpenApiRestCall_599368
proc url_GetBackupVaultAccessPolicy_600134(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupVaultAccessPolicy_600133(path: JsonNode; query: JsonNode;
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
  var valid_600135 = path.getOrDefault("backupVaultName")
  valid_600135 = validateParameter(valid_600135, JString, required = true,
                                 default = nil)
  if valid_600135 != nil:
    section.add "backupVaultName", valid_600135
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
  var valid_600136 = header.getOrDefault("X-Amz-Date")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Date", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Security-Token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Security-Token", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Content-Sha256", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Algorithm")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Algorithm", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Signature")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Signature", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-SignedHeaders", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Credential")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Credential", valid_600142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600143: Call_GetBackupVaultAccessPolicy_600132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access policy document that is associated with the named backup vault.
  ## 
  let valid = call_600143.validator(path, query, header, formData, body)
  let scheme = call_600143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600143.url(scheme.get, call_600143.host, call_600143.base,
                         call_600143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600143, url, valid)

proc call*(call_600144: Call_GetBackupVaultAccessPolicy_600132;
          backupVaultName: string): Recallable =
  ## getBackupVaultAccessPolicy
  ## Returns the access policy document that is associated with the named backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_600145 = newJObject()
  add(path_600145, "backupVaultName", newJString(backupVaultName))
  result = call_600144.call(path_600145, nil, nil, nil, nil)

var getBackupVaultAccessPolicy* = Call_GetBackupVaultAccessPolicy_600132(
    name: "getBackupVaultAccessPolicy", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_GetBackupVaultAccessPolicy_600133, base: "/",
    url: url_GetBackupVaultAccessPolicy_600134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultAccessPolicy_600162 = ref object of OpenApiRestCall_599368
proc url_DeleteBackupVaultAccessPolicy_600164(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupVaultAccessPolicy_600163(path: JsonNode; query: JsonNode;
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
  var valid_600165 = path.getOrDefault("backupVaultName")
  valid_600165 = validateParameter(valid_600165, JString, required = true,
                                 default = nil)
  if valid_600165 != nil:
    section.add "backupVaultName", valid_600165
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
  var valid_600166 = header.getOrDefault("X-Amz-Date")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Date", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Security-Token")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Security-Token", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Content-Sha256", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Algorithm")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Algorithm", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Signature")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Signature", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-SignedHeaders", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Credential")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Credential", valid_600172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600173: Call_DeleteBackupVaultAccessPolicy_600162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy document that manages permissions on a backup vault.
  ## 
  let valid = call_600173.validator(path, query, header, formData, body)
  let scheme = call_600173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600173.url(scheme.get, call_600173.host, call_600173.base,
                         call_600173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600173, url, valid)

proc call*(call_600174: Call_DeleteBackupVaultAccessPolicy_600162;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultAccessPolicy
  ## Deletes the policy document that manages permissions on a backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_600175 = newJObject()
  add(path_600175, "backupVaultName", newJString(backupVaultName))
  result = call_600174.call(path_600175, nil, nil, nil, nil)

var deleteBackupVaultAccessPolicy* = Call_DeleteBackupVaultAccessPolicy_600162(
    name: "deleteBackupVaultAccessPolicy", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_DeleteBackupVaultAccessPolicy_600163, base: "/",
    url: url_DeleteBackupVaultAccessPolicy_600164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultNotifications_600190 = ref object of OpenApiRestCall_599368
proc url_PutBackupVaultNotifications_600192(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBackupVaultNotifications_600191(path: JsonNode; query: JsonNode;
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
  var valid_600193 = path.getOrDefault("backupVaultName")
  valid_600193 = validateParameter(valid_600193, JString, required = true,
                                 default = nil)
  if valid_600193 != nil:
    section.add "backupVaultName", valid_600193
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
  var valid_600194 = header.getOrDefault("X-Amz-Date")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Date", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Security-Token")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Security-Token", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Content-Sha256", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Algorithm")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Algorithm", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Signature")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Signature", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-SignedHeaders", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Credential")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Credential", valid_600200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600202: Call_PutBackupVaultNotifications_600190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on notifications on a backup vault for the specified topic and events.
  ## 
  let valid = call_600202.validator(path, query, header, formData, body)
  let scheme = call_600202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600202.url(scheme.get, call_600202.host, call_600202.base,
                         call_600202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600202, url, valid)

proc call*(call_600203: Call_PutBackupVaultNotifications_600190;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultNotifications
  ## Turns on notifications on a backup vault for the specified topic and events.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_600204 = newJObject()
  var body_600205 = newJObject()
  add(path_600204, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_600205 = body
  result = call_600203.call(path_600204, nil, nil, nil, body_600205)

var putBackupVaultNotifications* = Call_PutBackupVaultNotifications_600190(
    name: "putBackupVaultNotifications", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_PutBackupVaultNotifications_600191, base: "/",
    url: url_PutBackupVaultNotifications_600192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultNotifications_600176 = ref object of OpenApiRestCall_599368
proc url_GetBackupVaultNotifications_600178(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupVaultNotifications_600177(path: JsonNode; query: JsonNode;
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
  var valid_600179 = path.getOrDefault("backupVaultName")
  valid_600179 = validateParameter(valid_600179, JString, required = true,
                                 default = nil)
  if valid_600179 != nil:
    section.add "backupVaultName", valid_600179
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
  var valid_600180 = header.getOrDefault("X-Amz-Date")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Date", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Security-Token")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Security-Token", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Content-Sha256", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Algorithm")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Algorithm", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Signature")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Signature", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-SignedHeaders", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Credential")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Credential", valid_600186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600187: Call_GetBackupVaultNotifications_600176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns event notifications for the specified backup vault.
  ## 
  let valid = call_600187.validator(path, query, header, formData, body)
  let scheme = call_600187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600187.url(scheme.get, call_600187.host, call_600187.base,
                         call_600187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600187, url, valid)

proc call*(call_600188: Call_GetBackupVaultNotifications_600176;
          backupVaultName: string): Recallable =
  ## getBackupVaultNotifications
  ## Returns event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_600189 = newJObject()
  add(path_600189, "backupVaultName", newJString(backupVaultName))
  result = call_600188.call(path_600189, nil, nil, nil, nil)

var getBackupVaultNotifications* = Call_GetBackupVaultNotifications_600176(
    name: "getBackupVaultNotifications", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_GetBackupVaultNotifications_600177, base: "/",
    url: url_GetBackupVaultNotifications_600178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultNotifications_600206 = ref object of OpenApiRestCall_599368
proc url_DeleteBackupVaultNotifications_600208(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupVaultNotifications_600207(path: JsonNode;
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
  var valid_600209 = path.getOrDefault("backupVaultName")
  valid_600209 = validateParameter(valid_600209, JString, required = true,
                                 default = nil)
  if valid_600209 != nil:
    section.add "backupVaultName", valid_600209
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
  var valid_600210 = header.getOrDefault("X-Amz-Date")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Date", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Security-Token")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Security-Token", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Content-Sha256", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Algorithm")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Algorithm", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Signature")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Signature", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-SignedHeaders", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Credential")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Credential", valid_600216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600217: Call_DeleteBackupVaultNotifications_600206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes event notifications for the specified backup vault.
  ## 
  let valid = call_600217.validator(path, query, header, formData, body)
  let scheme = call_600217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600217.url(scheme.get, call_600217.host, call_600217.base,
                         call_600217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600217, url, valid)

proc call*(call_600218: Call_DeleteBackupVaultNotifications_600206;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultNotifications
  ## Deletes event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_600219 = newJObject()
  add(path_600219, "backupVaultName", newJString(backupVaultName))
  result = call_600218.call(path_600219, nil, nil, nil, nil)

var deleteBackupVaultNotifications* = Call_DeleteBackupVaultNotifications_600206(
    name: "deleteBackupVaultNotifications", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_DeleteBackupVaultNotifications_600207, base: "/",
    url: url_DeleteBackupVaultNotifications_600208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecoveryPointLifecycle_600235 = ref object of OpenApiRestCall_599368
proc url_UpdateRecoveryPointLifecycle_600237(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRecoveryPointLifecycle_600236(path: JsonNode; query: JsonNode;
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
  var valid_600238 = path.getOrDefault("backupVaultName")
  valid_600238 = validateParameter(valid_600238, JString, required = true,
                                 default = nil)
  if valid_600238 != nil:
    section.add "backupVaultName", valid_600238
  var valid_600239 = path.getOrDefault("recoveryPointArn")
  valid_600239 = validateParameter(valid_600239, JString, required = true,
                                 default = nil)
  if valid_600239 != nil:
    section.add "recoveryPointArn", valid_600239
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
  var valid_600240 = header.getOrDefault("X-Amz-Date")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Date", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Security-Token")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Security-Token", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Content-Sha256", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Algorithm")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Algorithm", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Signature")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Signature", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-SignedHeaders", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Credential")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Credential", valid_600246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600248: Call_UpdateRecoveryPointLifecycle_600235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ## 
  let valid = call_600248.validator(path, query, header, formData, body)
  let scheme = call_600248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600248.url(scheme.get, call_600248.host, call_600248.base,
                         call_600248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600248, url, valid)

proc call*(call_600249: Call_UpdateRecoveryPointLifecycle_600235;
          backupVaultName: string; recoveryPointArn: string; body: JsonNode): Recallable =
  ## updateRecoveryPointLifecycle
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   body: JObject (required)
  var path_600250 = newJObject()
  var body_600251 = newJObject()
  add(path_600250, "backupVaultName", newJString(backupVaultName))
  add(path_600250, "recoveryPointArn", newJString(recoveryPointArn))
  if body != nil:
    body_600251 = body
  result = call_600249.call(path_600250, nil, nil, nil, body_600251)

var updateRecoveryPointLifecycle* = Call_UpdateRecoveryPointLifecycle_600235(
    name: "updateRecoveryPointLifecycle", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_UpdateRecoveryPointLifecycle_600236, base: "/",
    url: url_UpdateRecoveryPointLifecycle_600237,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecoveryPoint_600220 = ref object of OpenApiRestCall_599368
proc url_DescribeRecoveryPoint_600222(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRecoveryPoint_600221(path: JsonNode; query: JsonNode;
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
  var valid_600223 = path.getOrDefault("backupVaultName")
  valid_600223 = validateParameter(valid_600223, JString, required = true,
                                 default = nil)
  if valid_600223 != nil:
    section.add "backupVaultName", valid_600223
  var valid_600224 = path.getOrDefault("recoveryPointArn")
  valid_600224 = validateParameter(valid_600224, JString, required = true,
                                 default = nil)
  if valid_600224 != nil:
    section.add "recoveryPointArn", valid_600224
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
  var valid_600225 = header.getOrDefault("X-Amz-Date")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Date", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Security-Token")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Security-Token", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Content-Sha256", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Algorithm")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Algorithm", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Signature")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Signature", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-SignedHeaders", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Credential")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Credential", valid_600231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600232: Call_DescribeRecoveryPoint_600220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ## 
  let valid = call_600232.validator(path, query, header, formData, body)
  let scheme = call_600232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600232.url(scheme.get, call_600232.host, call_600232.base,
                         call_600232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600232, url, valid)

proc call*(call_600233: Call_DescribeRecoveryPoint_600220; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## describeRecoveryPoint
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_600234 = newJObject()
  add(path_600234, "backupVaultName", newJString(backupVaultName))
  add(path_600234, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_600233.call(path_600234, nil, nil, nil, nil)

var describeRecoveryPoint* = Call_DescribeRecoveryPoint_600220(
    name: "describeRecoveryPoint", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DescribeRecoveryPoint_600221, base: "/",
    url: url_DescribeRecoveryPoint_600222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRecoveryPoint_600252 = ref object of OpenApiRestCall_599368
proc url_DeleteRecoveryPoint_600254(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRecoveryPoint_600253(path: JsonNode; query: JsonNode;
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
  var valid_600255 = path.getOrDefault("backupVaultName")
  valid_600255 = validateParameter(valid_600255, JString, required = true,
                                 default = nil)
  if valid_600255 != nil:
    section.add "backupVaultName", valid_600255
  var valid_600256 = path.getOrDefault("recoveryPointArn")
  valid_600256 = validateParameter(valid_600256, JString, required = true,
                                 default = nil)
  if valid_600256 != nil:
    section.add "recoveryPointArn", valid_600256
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
  var valid_600257 = header.getOrDefault("X-Amz-Date")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Date", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Security-Token")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Security-Token", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Content-Sha256", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Algorithm")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Algorithm", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Signature")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Signature", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-SignedHeaders", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Credential")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Credential", valid_600263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600264: Call_DeleteRecoveryPoint_600252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recovery point specified by a recovery point ID.
  ## 
  let valid = call_600264.validator(path, query, header, formData, body)
  let scheme = call_600264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600264.url(scheme.get, call_600264.host, call_600264.base,
                         call_600264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600264, url, valid)

proc call*(call_600265: Call_DeleteRecoveryPoint_600252; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## deleteRecoveryPoint
  ## Deletes the recovery point specified by a recovery point ID.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_600266 = newJObject()
  add(path_600266, "backupVaultName", newJString(backupVaultName))
  add(path_600266, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_600265.call(path_600266, nil, nil, nil, nil)

var deleteRecoveryPoint* = Call_DeleteRecoveryPoint_600252(
    name: "deleteRecoveryPoint", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DeleteRecoveryPoint_600253, base: "/",
    url: url_DeleteRecoveryPoint_600254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBackupJob_600281 = ref object of OpenApiRestCall_599368
proc url_StopBackupJob_600283(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopBackupJob_600282(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600284 = path.getOrDefault("backupJobId")
  valid_600284 = validateParameter(valid_600284, JString, required = true,
                                 default = nil)
  if valid_600284 != nil:
    section.add "backupJobId", valid_600284
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
  var valid_600285 = header.getOrDefault("X-Amz-Date")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Date", valid_600285
  var valid_600286 = header.getOrDefault("X-Amz-Security-Token")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Security-Token", valid_600286
  var valid_600287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-Content-Sha256", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Algorithm")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Algorithm", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Signature")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Signature", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-SignedHeaders", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Credential")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Credential", valid_600291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600292: Call_StopBackupJob_600281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ## 
  let valid = call_600292.validator(path, query, header, formData, body)
  let scheme = call_600292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600292.url(scheme.get, call_600292.host, call_600292.base,
                         call_600292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600292, url, valid)

proc call*(call_600293: Call_StopBackupJob_600281; backupJobId: string): Recallable =
  ## stopBackupJob
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_600294 = newJObject()
  add(path_600294, "backupJobId", newJString(backupJobId))
  result = call_600293.call(path_600294, nil, nil, nil, nil)

var stopBackupJob* = Call_StopBackupJob_600281(name: "stopBackupJob",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_StopBackupJob_600282,
    base: "/", url: url_StopBackupJob_600283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupJob_600267 = ref object of OpenApiRestCall_599368
proc url_DescribeBackupJob_600269(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBackupJob_600268(path: JsonNode; query: JsonNode;
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
  var valid_600270 = path.getOrDefault("backupJobId")
  valid_600270 = validateParameter(valid_600270, JString, required = true,
                                 default = nil)
  if valid_600270 != nil:
    section.add "backupJobId", valid_600270
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
  var valid_600271 = header.getOrDefault("X-Amz-Date")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-Date", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Security-Token")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Security-Token", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Content-Sha256", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Algorithm")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Algorithm", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Signature")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Signature", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-SignedHeaders", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Credential")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Credential", valid_600277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600278: Call_DescribeBackupJob_600267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with creating a backup of a resource.
  ## 
  let valid = call_600278.validator(path, query, header, formData, body)
  let scheme = call_600278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600278.url(scheme.get, call_600278.host, call_600278.base,
                         call_600278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600278, url, valid)

proc call*(call_600279: Call_DescribeBackupJob_600267; backupJobId: string): Recallable =
  ## describeBackupJob
  ## Returns metadata associated with creating a backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_600280 = newJObject()
  add(path_600280, "backupJobId", newJString(backupJobId))
  result = call_600279.call(path_600280, nil, nil, nil, nil)

var describeBackupJob* = Call_DescribeBackupJob_600267(name: "describeBackupJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_DescribeBackupJob_600268,
    base: "/", url: url_DescribeBackupJob_600269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProtectedResource_600295 = ref object of OpenApiRestCall_599368
proc url_DescribeProtectedResource_600297(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeProtectedResource_600296(path: JsonNode; query: JsonNode;
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
  var valid_600298 = path.getOrDefault("resourceArn")
  valid_600298 = validateParameter(valid_600298, JString, required = true,
                                 default = nil)
  if valid_600298 != nil:
    section.add "resourceArn", valid_600298
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
  var valid_600299 = header.getOrDefault("X-Amz-Date")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Date", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Security-Token")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Security-Token", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Content-Sha256", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Algorithm")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Algorithm", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Signature")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Signature", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-SignedHeaders", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Credential")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Credential", valid_600305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600306: Call_DescribeProtectedResource_600295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ## 
  let valid = call_600306.validator(path, query, header, formData, body)
  let scheme = call_600306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600306.url(scheme.get, call_600306.host, call_600306.base,
                         call_600306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600306, url, valid)

proc call*(call_600307: Call_DescribeProtectedResource_600295; resourceArn: string): Recallable =
  ## describeProtectedResource
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the resource type.
  var path_600308 = newJObject()
  add(path_600308, "resourceArn", newJString(resourceArn))
  result = call_600307.call(path_600308, nil, nil, nil, nil)

var describeProtectedResource* = Call_DescribeProtectedResource_600295(
    name: "describeProtectedResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/{resourceArn}",
    validator: validate_DescribeProtectedResource_600296, base: "/",
    url: url_DescribeProtectedResource_600297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRestoreJob_600309 = ref object of OpenApiRestCall_599368
proc url_DescribeRestoreJob_600311(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRestoreJob_600310(path: JsonNode; query: JsonNode;
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
  var valid_600312 = path.getOrDefault("restoreJobId")
  valid_600312 = validateParameter(valid_600312, JString, required = true,
                                 default = nil)
  if valid_600312 != nil:
    section.add "restoreJobId", valid_600312
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
  var valid_600313 = header.getOrDefault("X-Amz-Date")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Date", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Security-Token")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Security-Token", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Content-Sha256", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Algorithm")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Algorithm", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Signature")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Signature", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-SignedHeaders", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-Credential")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Credential", valid_600319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600320: Call_DescribeRestoreJob_600309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ## 
  let valid = call_600320.validator(path, query, header, formData, body)
  let scheme = call_600320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600320.url(scheme.get, call_600320.host, call_600320.base,
                         call_600320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600320, url, valid)

proc call*(call_600321: Call_DescribeRestoreJob_600309; restoreJobId: string): Recallable =
  ## describeRestoreJob
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ##   restoreJobId: string (required)
  ##               : Uniquely identifies the job that restores a recovery point.
  var path_600322 = newJObject()
  add(path_600322, "restoreJobId", newJString(restoreJobId))
  result = call_600321.call(path_600322, nil, nil, nil, nil)

var describeRestoreJob* = Call_DescribeRestoreJob_600309(
    name: "describeRestoreJob", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/restore-jobs/{restoreJobId}",
    validator: validate_DescribeRestoreJob_600310, base: "/",
    url: url_DescribeRestoreJob_600311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBackupPlanTemplate_600323 = ref object of OpenApiRestCall_599368
proc url_ExportBackupPlanTemplate_600325(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportBackupPlanTemplate_600324(path: JsonNode; query: JsonNode;
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
  var valid_600326 = path.getOrDefault("backupPlanId")
  valid_600326 = validateParameter(valid_600326, JString, required = true,
                                 default = nil)
  if valid_600326 != nil:
    section.add "backupPlanId", valid_600326
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
  var valid_600327 = header.getOrDefault("X-Amz-Date")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Date", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Security-Token")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Security-Token", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Content-Sha256", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Algorithm")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Algorithm", valid_600330
  var valid_600331 = header.getOrDefault("X-Amz-Signature")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Signature", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-SignedHeaders", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Credential")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Credential", valid_600333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600334: Call_ExportBackupPlanTemplate_600323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ## 
  let valid = call_600334.validator(path, query, header, formData, body)
  let scheme = call_600334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600334.url(scheme.get, call_600334.host, call_600334.base,
                         call_600334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600334, url, valid)

proc call*(call_600335: Call_ExportBackupPlanTemplate_600323; backupPlanId: string): Recallable =
  ## exportBackupPlanTemplate
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_600336 = newJObject()
  add(path_600336, "backupPlanId", newJString(backupPlanId))
  result = call_600335.call(path_600336, nil, nil, nil, nil)

var exportBackupPlanTemplate* = Call_ExportBackupPlanTemplate_600323(
    name: "exportBackupPlanTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/toTemplate/",
    validator: validate_ExportBackupPlanTemplate_600324, base: "/",
    url: url_ExportBackupPlanTemplate_600325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlan_600337 = ref object of OpenApiRestCall_599368
proc url_GetBackupPlan_600339(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupPlan_600338(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600340 = path.getOrDefault("backupPlanId")
  valid_600340 = validateParameter(valid_600340, JString, required = true,
                                 default = nil)
  if valid_600340 != nil:
    section.add "backupPlanId", valid_600340
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  section = newJObject()
  var valid_600341 = query.getOrDefault("versionId")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "versionId", valid_600341
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
  var valid_600342 = header.getOrDefault("X-Amz-Date")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Date", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Security-Token")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Security-Token", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Content-Sha256", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Algorithm")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Algorithm", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Signature")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Signature", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-SignedHeaders", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Credential")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Credential", valid_600348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600349: Call_GetBackupPlan_600337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ## 
  let valid = call_600349.validator(path, query, header, formData, body)
  let scheme = call_600349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600349.url(scheme.get, call_600349.host, call_600349.base,
                         call_600349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600349, url, valid)

proc call*(call_600350: Call_GetBackupPlan_600337; backupPlanId: string;
          versionId: string = ""): Recallable =
  ## getBackupPlan
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ##   versionId: string
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_600351 = newJObject()
  var query_600352 = newJObject()
  add(query_600352, "versionId", newJString(versionId))
  add(path_600351, "backupPlanId", newJString(backupPlanId))
  result = call_600350.call(path_600351, query_600352, nil, nil, nil)

var getBackupPlan* = Call_GetBackupPlan_600337(name: "getBackupPlan",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/", validator: validate_GetBackupPlan_600338,
    base: "/", url: url_GetBackupPlan_600339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromJSON_600353 = ref object of OpenApiRestCall_599368
proc url_GetBackupPlanFromJSON_600355(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBackupPlanFromJSON_600354(path: JsonNode; query: JsonNode;
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
  var valid_600356 = header.getOrDefault("X-Amz-Date")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Date", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Security-Token")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Security-Token", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Content-Sha256", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Algorithm")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Algorithm", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Signature")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Signature", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-SignedHeaders", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Credential")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Credential", valid_600362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600364: Call_GetBackupPlanFromJSON_600353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a valid JSON document specifying a backup plan or an error.
  ## 
  let valid = call_600364.validator(path, query, header, formData, body)
  let scheme = call_600364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600364.url(scheme.get, call_600364.host, call_600364.base,
                         call_600364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600364, url, valid)

proc call*(call_600365: Call_GetBackupPlanFromJSON_600353; body: JsonNode): Recallable =
  ## getBackupPlanFromJSON
  ## Returns a valid JSON document specifying a backup plan or an error.
  ##   body: JObject (required)
  var body_600366 = newJObject()
  if body != nil:
    body_600366 = body
  result = call_600365.call(nil, nil, nil, nil, body_600366)

var getBackupPlanFromJSON* = Call_GetBackupPlanFromJSON_600353(
    name: "getBackupPlanFromJSON", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup/template/json/toPlan",
    validator: validate_GetBackupPlanFromJSON_600354, base: "/",
    url: url_GetBackupPlanFromJSON_600355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromTemplate_600367 = ref object of OpenApiRestCall_599368
proc url_GetBackupPlanFromTemplate_600369(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupPlanFromTemplate_600368(path: JsonNode; query: JsonNode;
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
  var valid_600370 = path.getOrDefault("templateId")
  valid_600370 = validateParameter(valid_600370, JString, required = true,
                                 default = nil)
  if valid_600370 != nil:
    section.add "templateId", valid_600370
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
  var valid_600371 = header.getOrDefault("X-Amz-Date")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Date", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Security-Token")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Security-Token", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Content-Sha256", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Algorithm")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Algorithm", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Signature")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Signature", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-SignedHeaders", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Credential")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Credential", valid_600377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600378: Call_GetBackupPlanFromTemplate_600367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ## 
  let valid = call_600378.validator(path, query, header, formData, body)
  let scheme = call_600378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600378.url(scheme.get, call_600378.host, call_600378.base,
                         call_600378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600378, url, valid)

proc call*(call_600379: Call_GetBackupPlanFromTemplate_600367; templateId: string): Recallable =
  ## getBackupPlanFromTemplate
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ##   templateId: string (required)
  ##             : Uniquely identifies a stored backup plan template.
  var path_600380 = newJObject()
  add(path_600380, "templateId", newJString(templateId))
  result = call_600379.call(path_600380, nil, nil, nil, nil)

var getBackupPlanFromTemplate* = Call_GetBackupPlanFromTemplate_600367(
    name: "getBackupPlanFromTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/template/plans/{templateId}/toPlan",
    validator: validate_GetBackupPlanFromTemplate_600368, base: "/",
    url: url_GetBackupPlanFromTemplate_600369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecoveryPointRestoreMetadata_600381 = ref object of OpenApiRestCall_599368
proc url_GetRecoveryPointRestoreMetadata_600383(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRecoveryPointRestoreMetadata_600382(path: JsonNode;
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
  var valid_600384 = path.getOrDefault("backupVaultName")
  valid_600384 = validateParameter(valid_600384, JString, required = true,
                                 default = nil)
  if valid_600384 != nil:
    section.add "backupVaultName", valid_600384
  var valid_600385 = path.getOrDefault("recoveryPointArn")
  valid_600385 = validateParameter(valid_600385, JString, required = true,
                                 default = nil)
  if valid_600385 != nil:
    section.add "recoveryPointArn", valid_600385
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
  var valid_600386 = header.getOrDefault("X-Amz-Date")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Date", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Security-Token")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Security-Token", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Content-Sha256", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Algorithm")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Algorithm", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Signature")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Signature", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-SignedHeaders", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Credential")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Credential", valid_600392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600393: Call_GetRecoveryPointRestoreMetadata_600381;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns two sets of metadata key-value pairs. The first set lists the metadata that the recovery point was created with. The second set lists the metadata key-value pairs that are required to restore the recovery point.</p> <p>These sets can be the same, or the restore metadata set can contain different values if the target service to be restored has changed since the recovery point was created and now requires additional or different information in order to be restored.</p>
  ## 
  let valid = call_600393.validator(path, query, header, formData, body)
  let scheme = call_600393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600393.url(scheme.get, call_600393.host, call_600393.base,
                         call_600393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600393, url, valid)

proc call*(call_600394: Call_GetRecoveryPointRestoreMetadata_600381;
          backupVaultName: string; recoveryPointArn: string): Recallable =
  ## getRecoveryPointRestoreMetadata
  ## <p>Returns two sets of metadata key-value pairs. The first set lists the metadata that the recovery point was created with. The second set lists the metadata key-value pairs that are required to restore the recovery point.</p> <p>These sets can be the same, or the restore metadata set can contain different values if the target service to be restored has changed since the recovery point was created and now requires additional or different information in order to be restored.</p>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_600395 = newJObject()
  add(path_600395, "backupVaultName", newJString(backupVaultName))
  add(path_600395, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_600394.call(path_600395, nil, nil, nil, nil)

var getRecoveryPointRestoreMetadata* = Call_GetRecoveryPointRestoreMetadata_600381(
    name: "getRecoveryPointRestoreMetadata", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}/restore-metadata",
    validator: validate_GetRecoveryPointRestoreMetadata_600382, base: "/",
    url: url_GetRecoveryPointRestoreMetadata_600383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSupportedResourceTypes_600396 = ref object of OpenApiRestCall_599368
proc url_GetSupportedResourceTypes_600398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSupportedResourceTypes_600397(path: JsonNode; query: JsonNode;
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
  var valid_600399 = header.getOrDefault("X-Amz-Date")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Date", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Security-Token")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Security-Token", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Content-Sha256", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Algorithm")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Algorithm", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-Signature")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Signature", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-SignedHeaders", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Credential")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Credential", valid_600405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600406: Call_GetSupportedResourceTypes_600396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the AWS resource types supported by AWS Backup.
  ## 
  let valid = call_600406.validator(path, query, header, formData, body)
  let scheme = call_600406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600406.url(scheme.get, call_600406.host, call_600406.base,
                         call_600406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600406, url, valid)

proc call*(call_600407: Call_GetSupportedResourceTypes_600396): Recallable =
  ## getSupportedResourceTypes
  ## Returns the AWS resource types supported by AWS Backup.
  result = call_600407.call(nil, nil, nil, nil, nil)

var getSupportedResourceTypes* = Call_GetSupportedResourceTypes_600396(
    name: "getSupportedResourceTypes", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/supported-resource-types",
    validator: validate_GetSupportedResourceTypes_600397, base: "/",
    url: url_GetSupportedResourceTypes_600398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupJobs_600408 = ref object of OpenApiRestCall_599368
proc url_ListBackupJobs_600410(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBackupJobs_600409(path: JsonNode; query: JsonNode;
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
  var valid_600411 = query.getOrDefault("createdBefore")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "createdBefore", valid_600411
  var valid_600412 = query.getOrDefault("createdAfter")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "createdAfter", valid_600412
  var valid_600413 = query.getOrDefault("resourceArn")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "resourceArn", valid_600413
  var valid_600414 = query.getOrDefault("NextToken")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "NextToken", valid_600414
  var valid_600415 = query.getOrDefault("maxResults")
  valid_600415 = validateParameter(valid_600415, JInt, required = false, default = nil)
  if valid_600415 != nil:
    section.add "maxResults", valid_600415
  var valid_600416 = query.getOrDefault("nextToken")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "nextToken", valid_600416
  var valid_600417 = query.getOrDefault("backupVaultName")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "backupVaultName", valid_600417
  var valid_600431 = query.getOrDefault("state")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = newJString("CREATED"))
  if valid_600431 != nil:
    section.add "state", valid_600431
  var valid_600432 = query.getOrDefault("resourceType")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "resourceType", valid_600432
  var valid_600433 = query.getOrDefault("MaxResults")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "MaxResults", valid_600433
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
  var valid_600434 = header.getOrDefault("X-Amz-Date")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Date", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Security-Token")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Security-Token", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Content-Sha256", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Algorithm")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Algorithm", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Signature")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Signature", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-SignedHeaders", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Credential")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Credential", valid_600440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600441: Call_ListBackupJobs_600408; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about your backup jobs.
  ## 
  let valid = call_600441.validator(path, query, header, formData, body)
  let scheme = call_600441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600441.url(scheme.get, call_600441.host, call_600441.base,
                         call_600441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600441, url, valid)

proc call*(call_600442: Call_ListBackupJobs_600408; createdBefore: string = "";
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
  var query_600443 = newJObject()
  add(query_600443, "createdBefore", newJString(createdBefore))
  add(query_600443, "createdAfter", newJString(createdAfter))
  add(query_600443, "resourceArn", newJString(resourceArn))
  add(query_600443, "NextToken", newJString(NextToken))
  add(query_600443, "maxResults", newJInt(maxResults))
  add(query_600443, "nextToken", newJString(nextToken))
  add(query_600443, "backupVaultName", newJString(backupVaultName))
  add(query_600443, "state", newJString(state))
  add(query_600443, "resourceType", newJString(resourceType))
  add(query_600443, "MaxResults", newJString(MaxResults))
  result = call_600442.call(nil, query_600443, nil, nil, nil)

var listBackupJobs* = Call_ListBackupJobs_600408(name: "listBackupJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup-jobs/",
    validator: validate_ListBackupJobs_600409, base: "/", url: url_ListBackupJobs_600410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanTemplates_600444 = ref object of OpenApiRestCall_599368
proc url_ListBackupPlanTemplates_600446(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBackupPlanTemplates_600445(path: JsonNode; query: JsonNode;
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
  var valid_600447 = query.getOrDefault("NextToken")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "NextToken", valid_600447
  var valid_600448 = query.getOrDefault("maxResults")
  valid_600448 = validateParameter(valid_600448, JInt, required = false, default = nil)
  if valid_600448 != nil:
    section.add "maxResults", valid_600448
  var valid_600449 = query.getOrDefault("nextToken")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "nextToken", valid_600449
  var valid_600450 = query.getOrDefault("MaxResults")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "MaxResults", valid_600450
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
  var valid_600451 = header.getOrDefault("X-Amz-Date")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Date", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Security-Token")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Security-Token", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Content-Sha256", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Algorithm")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Algorithm", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Signature")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Signature", valid_600455
  var valid_600456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-SignedHeaders", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-Credential")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Credential", valid_600457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600458: Call_ListBackupPlanTemplates_600444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ## 
  let valid = call_600458.validator(path, query, header, formData, body)
  let scheme = call_600458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600458.url(scheme.get, call_600458.host, call_600458.base,
                         call_600458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600458, url, valid)

proc call*(call_600459: Call_ListBackupPlanTemplates_600444;
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
  var query_600460 = newJObject()
  add(query_600460, "NextToken", newJString(NextToken))
  add(query_600460, "maxResults", newJInt(maxResults))
  add(query_600460, "nextToken", newJString(nextToken))
  add(query_600460, "MaxResults", newJString(MaxResults))
  result = call_600459.call(nil, query_600460, nil, nil, nil)

var listBackupPlanTemplates* = Call_ListBackupPlanTemplates_600444(
    name: "listBackupPlanTemplates", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/template/plans",
    validator: validate_ListBackupPlanTemplates_600445, base: "/",
    url: url_ListBackupPlanTemplates_600446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanVersions_600461 = ref object of OpenApiRestCall_599368
proc url_ListBackupPlanVersions_600463(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBackupPlanVersions_600462(path: JsonNode; query: JsonNode;
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
  var valid_600464 = path.getOrDefault("backupPlanId")
  valid_600464 = validateParameter(valid_600464, JString, required = true,
                                 default = nil)
  if valid_600464 != nil:
    section.add "backupPlanId", valid_600464
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
  var valid_600465 = query.getOrDefault("NextToken")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "NextToken", valid_600465
  var valid_600466 = query.getOrDefault("maxResults")
  valid_600466 = validateParameter(valid_600466, JInt, required = false, default = nil)
  if valid_600466 != nil:
    section.add "maxResults", valid_600466
  var valid_600467 = query.getOrDefault("nextToken")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "nextToken", valid_600467
  var valid_600468 = query.getOrDefault("MaxResults")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "MaxResults", valid_600468
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
  var valid_600469 = header.getOrDefault("X-Amz-Date")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-Date", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-Security-Token")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-Security-Token", valid_600470
  var valid_600471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Content-Sha256", valid_600471
  var valid_600472 = header.getOrDefault("X-Amz-Algorithm")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Algorithm", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Signature")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Signature", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-SignedHeaders", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Credential")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Credential", valid_600475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600476: Call_ListBackupPlanVersions_600461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ## 
  let valid = call_600476.validator(path, query, header, formData, body)
  let scheme = call_600476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600476.url(scheme.get, call_600476.host, call_600476.base,
                         call_600476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600476, url, valid)

proc call*(call_600477: Call_ListBackupPlanVersions_600461; backupPlanId: string;
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
  var path_600478 = newJObject()
  var query_600479 = newJObject()
  add(path_600478, "backupPlanId", newJString(backupPlanId))
  add(query_600479, "NextToken", newJString(NextToken))
  add(query_600479, "maxResults", newJInt(maxResults))
  add(query_600479, "nextToken", newJString(nextToken))
  add(query_600479, "MaxResults", newJString(MaxResults))
  result = call_600477.call(path_600478, query_600479, nil, nil, nil)

var listBackupPlanVersions* = Call_ListBackupPlanVersions_600461(
    name: "listBackupPlanVersions", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/plans/{backupPlanId}/versions/",
    validator: validate_ListBackupPlanVersions_600462, base: "/",
    url: url_ListBackupPlanVersions_600463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupVaults_600480 = ref object of OpenApiRestCall_599368
proc url_ListBackupVaults_600482(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBackupVaults_600481(path: JsonNode; query: JsonNode;
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
  var valid_600483 = query.getOrDefault("NextToken")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "NextToken", valid_600483
  var valid_600484 = query.getOrDefault("maxResults")
  valid_600484 = validateParameter(valid_600484, JInt, required = false, default = nil)
  if valid_600484 != nil:
    section.add "maxResults", valid_600484
  var valid_600485 = query.getOrDefault("nextToken")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "nextToken", valid_600485
  var valid_600486 = query.getOrDefault("MaxResults")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "MaxResults", valid_600486
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
  var valid_600487 = header.getOrDefault("X-Amz-Date")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Date", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Security-Token")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Security-Token", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Content-Sha256", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Algorithm")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Algorithm", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Signature")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Signature", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-SignedHeaders", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-Credential")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-Credential", valid_600493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600494: Call_ListBackupVaults_600480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of recovery point storage containers along with information about them.
  ## 
  let valid = call_600494.validator(path, query, header, formData, body)
  let scheme = call_600494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600494.url(scheme.get, call_600494.host, call_600494.base,
                         call_600494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600494, url, valid)

proc call*(call_600495: Call_ListBackupVaults_600480; NextToken: string = "";
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
  var query_600496 = newJObject()
  add(query_600496, "NextToken", newJString(NextToken))
  add(query_600496, "maxResults", newJInt(maxResults))
  add(query_600496, "nextToken", newJString(nextToken))
  add(query_600496, "MaxResults", newJString(MaxResults))
  result = call_600495.call(nil, query_600496, nil, nil, nil)

var listBackupVaults* = Call_ListBackupVaults_600480(name: "listBackupVaults",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-vaults/", validator: validate_ListBackupVaults_600481,
    base: "/", url: url_ListBackupVaults_600482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProtectedResources_600497 = ref object of OpenApiRestCall_599368
proc url_ListProtectedResources_600499(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProtectedResources_600498(path: JsonNode; query: JsonNode;
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
  var valid_600500 = query.getOrDefault("NextToken")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "NextToken", valid_600500
  var valid_600501 = query.getOrDefault("maxResults")
  valid_600501 = validateParameter(valid_600501, JInt, required = false, default = nil)
  if valid_600501 != nil:
    section.add "maxResults", valid_600501
  var valid_600502 = query.getOrDefault("nextToken")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "nextToken", valid_600502
  var valid_600503 = query.getOrDefault("MaxResults")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "MaxResults", valid_600503
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
  var valid_600504 = header.getOrDefault("X-Amz-Date")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Date", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Security-Token")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Security-Token", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Content-Sha256", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Algorithm")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Algorithm", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Signature")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Signature", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-SignedHeaders", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Credential")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Credential", valid_600510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600511: Call_ListProtectedResources_600497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ## 
  let valid = call_600511.validator(path, query, header, formData, body)
  let scheme = call_600511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600511.url(scheme.get, call_600511.host, call_600511.base,
                         call_600511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600511, url, valid)

proc call*(call_600512: Call_ListProtectedResources_600497; NextToken: string = "";
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
  var query_600513 = newJObject()
  add(query_600513, "NextToken", newJString(NextToken))
  add(query_600513, "maxResults", newJInt(maxResults))
  add(query_600513, "nextToken", newJString(nextToken))
  add(query_600513, "MaxResults", newJString(MaxResults))
  result = call_600512.call(nil, query_600513, nil, nil, nil)

var listProtectedResources* = Call_ListProtectedResources_600497(
    name: "listProtectedResources", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/",
    validator: validate_ListProtectedResources_600498, base: "/",
    url: url_ListProtectedResources_600499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByBackupVault_600514 = ref object of OpenApiRestCall_599368
proc url_ListRecoveryPointsByBackupVault_600516(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRecoveryPointsByBackupVault_600515(path: JsonNode;
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
  var valid_600517 = path.getOrDefault("backupVaultName")
  valid_600517 = validateParameter(valid_600517, JString, required = true,
                                 default = nil)
  if valid_600517 != nil:
    section.add "backupVaultName", valid_600517
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
  var valid_600518 = query.getOrDefault("createdBefore")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "createdBefore", valid_600518
  var valid_600519 = query.getOrDefault("createdAfter")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "createdAfter", valid_600519
  var valid_600520 = query.getOrDefault("resourceArn")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "resourceArn", valid_600520
  var valid_600521 = query.getOrDefault("backupPlanId")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "backupPlanId", valid_600521
  var valid_600522 = query.getOrDefault("NextToken")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "NextToken", valid_600522
  var valid_600523 = query.getOrDefault("maxResults")
  valid_600523 = validateParameter(valid_600523, JInt, required = false, default = nil)
  if valid_600523 != nil:
    section.add "maxResults", valid_600523
  var valid_600524 = query.getOrDefault("nextToken")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "nextToken", valid_600524
  var valid_600525 = query.getOrDefault("resourceType")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "resourceType", valid_600525
  var valid_600526 = query.getOrDefault("MaxResults")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "MaxResults", valid_600526
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
  var valid_600527 = header.getOrDefault("X-Amz-Date")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Date", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Security-Token")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Security-Token", valid_600528
  var valid_600529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-Content-Sha256", valid_600529
  var valid_600530 = header.getOrDefault("X-Amz-Algorithm")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Algorithm", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-Signature")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-Signature", valid_600531
  var valid_600532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-SignedHeaders", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Credential")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Credential", valid_600533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600534: Call_ListRecoveryPointsByBackupVault_600514;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns detailed information about the recovery points stored in a backup vault.
  ## 
  let valid = call_600534.validator(path, query, header, formData, body)
  let scheme = call_600534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600534.url(scheme.get, call_600534.host, call_600534.base,
                         call_600534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600534, url, valid)

proc call*(call_600535: Call_ListRecoveryPointsByBackupVault_600514;
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
  var path_600536 = newJObject()
  var query_600537 = newJObject()
  add(query_600537, "createdBefore", newJString(createdBefore))
  add(query_600537, "createdAfter", newJString(createdAfter))
  add(query_600537, "resourceArn", newJString(resourceArn))
  add(query_600537, "backupPlanId", newJString(backupPlanId))
  add(query_600537, "NextToken", newJString(NextToken))
  add(path_600536, "backupVaultName", newJString(backupVaultName))
  add(query_600537, "maxResults", newJInt(maxResults))
  add(query_600537, "nextToken", newJString(nextToken))
  add(query_600537, "resourceType", newJString(resourceType))
  add(query_600537, "MaxResults", newJString(MaxResults))
  result = call_600535.call(path_600536, query_600537, nil, nil, nil)

var listRecoveryPointsByBackupVault* = Call_ListRecoveryPointsByBackupVault_600514(
    name: "listRecoveryPointsByBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/recovery-points/",
    validator: validate_ListRecoveryPointsByBackupVault_600515, base: "/",
    url: url_ListRecoveryPointsByBackupVault_600516,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByResource_600538 = ref object of OpenApiRestCall_599368
proc url_ListRecoveryPointsByResource_600540(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRecoveryPointsByResource_600539(path: JsonNode; query: JsonNode;
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
  var valid_600541 = path.getOrDefault("resourceArn")
  valid_600541 = validateParameter(valid_600541, JString, required = true,
                                 default = nil)
  if valid_600541 != nil:
    section.add "resourceArn", valid_600541
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
  var valid_600542 = query.getOrDefault("NextToken")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "NextToken", valid_600542
  var valid_600543 = query.getOrDefault("maxResults")
  valid_600543 = validateParameter(valid_600543, JInt, required = false, default = nil)
  if valid_600543 != nil:
    section.add "maxResults", valid_600543
  var valid_600544 = query.getOrDefault("nextToken")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "nextToken", valid_600544
  var valid_600545 = query.getOrDefault("MaxResults")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "MaxResults", valid_600545
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
  var valid_600546 = header.getOrDefault("X-Amz-Date")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Date", valid_600546
  var valid_600547 = header.getOrDefault("X-Amz-Security-Token")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-Security-Token", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Content-Sha256", valid_600548
  var valid_600549 = header.getOrDefault("X-Amz-Algorithm")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = nil)
  if valid_600549 != nil:
    section.add "X-Amz-Algorithm", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-Signature")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Signature", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-SignedHeaders", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Credential")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Credential", valid_600552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600553: Call_ListRecoveryPointsByResource_600538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ## 
  let valid = call_600553.validator(path, query, header, formData, body)
  let scheme = call_600553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600553.url(scheme.get, call_600553.host, call_600553.base,
                         call_600553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600553, url, valid)

proc call*(call_600554: Call_ListRecoveryPointsByResource_600538;
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
  var path_600555 = newJObject()
  var query_600556 = newJObject()
  add(query_600556, "NextToken", newJString(NextToken))
  add(query_600556, "maxResults", newJInt(maxResults))
  add(query_600556, "nextToken", newJString(nextToken))
  add(path_600555, "resourceArn", newJString(resourceArn))
  add(query_600556, "MaxResults", newJString(MaxResults))
  result = call_600554.call(path_600555, query_600556, nil, nil, nil)

var listRecoveryPointsByResource* = Call_ListRecoveryPointsByResource_600538(
    name: "listRecoveryPointsByResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/resources/{resourceArn}/recovery-points/",
    validator: validate_ListRecoveryPointsByResource_600539, base: "/",
    url: url_ListRecoveryPointsByResource_600540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRestoreJobs_600557 = ref object of OpenApiRestCall_599368
proc url_ListRestoreJobs_600559(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRestoreJobs_600558(path: JsonNode; query: JsonNode;
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
  var valid_600560 = query.getOrDefault("NextToken")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "NextToken", valid_600560
  var valid_600561 = query.getOrDefault("maxResults")
  valid_600561 = validateParameter(valid_600561, JInt, required = false, default = nil)
  if valid_600561 != nil:
    section.add "maxResults", valid_600561
  var valid_600562 = query.getOrDefault("nextToken")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "nextToken", valid_600562
  var valid_600563 = query.getOrDefault("MaxResults")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "MaxResults", valid_600563
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
  var valid_600564 = header.getOrDefault("X-Amz-Date")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Date", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Security-Token")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Security-Token", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Content-Sha256", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Algorithm")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Algorithm", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-Signature")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-Signature", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-SignedHeaders", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Credential")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Credential", valid_600570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600571: Call_ListRestoreJobs_600557; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ## 
  let valid = call_600571.validator(path, query, header, formData, body)
  let scheme = call_600571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600571.url(scheme.get, call_600571.host, call_600571.base,
                         call_600571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600571, url, valid)

proc call*(call_600572: Call_ListRestoreJobs_600557; NextToken: string = "";
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
  var query_600573 = newJObject()
  add(query_600573, "NextToken", newJString(NextToken))
  add(query_600573, "maxResults", newJInt(maxResults))
  add(query_600573, "nextToken", newJString(nextToken))
  add(query_600573, "MaxResults", newJString(MaxResults))
  result = call_600572.call(nil, query_600573, nil, nil, nil)

var listRestoreJobs* = Call_ListRestoreJobs_600557(name: "listRestoreJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/restore-jobs/",
    validator: validate_ListRestoreJobs_600558, base: "/", url: url_ListRestoreJobs_600559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_600574 = ref object of OpenApiRestCall_599368
proc url_ListTags_600576(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTags_600575(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600577 = path.getOrDefault("resourceArn")
  valid_600577 = validateParameter(valid_600577, JString, required = true,
                                 default = nil)
  if valid_600577 != nil:
    section.add "resourceArn", valid_600577
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
  var valid_600578 = query.getOrDefault("NextToken")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "NextToken", valid_600578
  var valid_600579 = query.getOrDefault("maxResults")
  valid_600579 = validateParameter(valid_600579, JInt, required = false, default = nil)
  if valid_600579 != nil:
    section.add "maxResults", valid_600579
  var valid_600580 = query.getOrDefault("nextToken")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "nextToken", valid_600580
  var valid_600581 = query.getOrDefault("MaxResults")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "MaxResults", valid_600581
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
  var valid_600582 = header.getOrDefault("X-Amz-Date")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Date", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-Security-Token")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-Security-Token", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Content-Sha256", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Algorithm")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Algorithm", valid_600585
  var valid_600586 = header.getOrDefault("X-Amz-Signature")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-Signature", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-SignedHeaders", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Credential")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Credential", valid_600588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600589: Call_ListTags_600574; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ## 
  let valid = call_600589.validator(path, query, header, formData, body)
  let scheme = call_600589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600589.url(scheme.get, call_600589.host, call_600589.base,
                         call_600589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600589, url, valid)

proc call*(call_600590: Call_ListTags_600574; resourceArn: string;
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
  var path_600591 = newJObject()
  var query_600592 = newJObject()
  add(query_600592, "NextToken", newJString(NextToken))
  add(query_600592, "maxResults", newJInt(maxResults))
  add(query_600592, "nextToken", newJString(nextToken))
  add(path_600591, "resourceArn", newJString(resourceArn))
  add(query_600592, "MaxResults", newJString(MaxResults))
  result = call_600590.call(path_600591, query_600592, nil, nil, nil)

var listTags* = Call_ListTags_600574(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "backup.amazonaws.com",
                                  route: "/tags/{resourceArn}/",
                                  validator: validate_ListTags_600575, base: "/",
                                  url: url_ListTags_600576,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBackupJob_600593 = ref object of OpenApiRestCall_599368
proc url_StartBackupJob_600595(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartBackupJob_600594(path: JsonNode; query: JsonNode;
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
  var valid_600596 = header.getOrDefault("X-Amz-Date")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Date", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Security-Token")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Security-Token", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-Content-Sha256", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Algorithm")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Algorithm", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-Signature")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Signature", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-SignedHeaders", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Credential")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Credential", valid_600602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600604: Call_StartBackupJob_600593; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to create a one-time backup of the specified resource.
  ## 
  let valid = call_600604.validator(path, query, header, formData, body)
  let scheme = call_600604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600604.url(scheme.get, call_600604.host, call_600604.base,
                         call_600604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600604, url, valid)

proc call*(call_600605: Call_StartBackupJob_600593; body: JsonNode): Recallable =
  ## startBackupJob
  ## Starts a job to create a one-time backup of the specified resource.
  ##   body: JObject (required)
  var body_600606 = newJObject()
  if body != nil:
    body_600606 = body
  result = call_600605.call(nil, nil, nil, nil, body_600606)

var startBackupJob* = Call_StartBackupJob_600593(name: "startBackupJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup-jobs",
    validator: validate_StartBackupJob_600594, base: "/", url: url_StartBackupJob_600595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRestoreJob_600607 = ref object of OpenApiRestCall_599368
proc url_StartRestoreJob_600609(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartRestoreJob_600608(path: JsonNode; query: JsonNode;
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
  var valid_600610 = header.getOrDefault("X-Amz-Date")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Date", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Security-Token")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Security-Token", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Content-Sha256", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-Algorithm")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-Algorithm", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-Signature")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Signature", valid_600614
  var valid_600615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-SignedHeaders", valid_600615
  var valid_600616 = header.getOrDefault("X-Amz-Credential")
  valid_600616 = validateParameter(valid_600616, JString, required = false,
                                 default = nil)
  if valid_600616 != nil:
    section.add "X-Amz-Credential", valid_600616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600618: Call_StartRestoreJob_600607; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ## 
  let valid = call_600618.validator(path, query, header, formData, body)
  let scheme = call_600618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600618.url(scheme.get, call_600618.host, call_600618.base,
                         call_600618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600618, url, valid)

proc call*(call_600619: Call_StartRestoreJob_600607; body: JsonNode): Recallable =
  ## startRestoreJob
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ##   body: JObject (required)
  var body_600620 = newJObject()
  if body != nil:
    body_600620 = body
  result = call_600619.call(nil, nil, nil, nil, body_600620)

var startRestoreJob* = Call_StartRestoreJob_600607(name: "startRestoreJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/restore-jobs",
    validator: validate_StartRestoreJob_600608, base: "/", url: url_StartRestoreJob_600609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600621 = ref object of OpenApiRestCall_599368
proc url_TagResource_600623(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_600622(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600624 = path.getOrDefault("resourceArn")
  valid_600624 = validateParameter(valid_600624, JString, required = true,
                                 default = nil)
  if valid_600624 != nil:
    section.add "resourceArn", valid_600624
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
  var valid_600625 = header.getOrDefault("X-Amz-Date")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Date", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Security-Token")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Security-Token", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Content-Sha256", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-Algorithm")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-Algorithm", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Signature")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Signature", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-SignedHeaders", valid_600630
  var valid_600631 = header.getOrDefault("X-Amz-Credential")
  valid_600631 = validateParameter(valid_600631, JString, required = false,
                                 default = nil)
  if valid_600631 != nil:
    section.add "X-Amz-Credential", valid_600631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600633: Call_TagResource_600621; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ## 
  let valid = call_600633.validator(path, query, header, formData, body)
  let scheme = call_600633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600633.url(scheme.get, call_600633.host, call_600633.base,
                         call_600633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600633, url, valid)

proc call*(call_600634: Call_TagResource_600621; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  var path_600635 = newJObject()
  var body_600636 = newJObject()
  if body != nil:
    body_600636 = body
  add(path_600635, "resourceArn", newJString(resourceArn))
  result = call_600634.call(path_600635, nil, nil, nil, body_600636)

var tagResource* = Call_TagResource_600621(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "backup.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_600622,
                                        base: "/", url: url_TagResource_600623,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600637 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600639(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_600638(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600640 = path.getOrDefault("resourceArn")
  valid_600640 = validateParameter(valid_600640, JString, required = true,
                                 default = nil)
  if valid_600640 != nil:
    section.add "resourceArn", valid_600640
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
  var valid_600641 = header.getOrDefault("X-Amz-Date")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Date", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Security-Token")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Security-Token", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-Content-Sha256", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-Algorithm")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Algorithm", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Signature")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Signature", valid_600645
  var valid_600646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600646 = validateParameter(valid_600646, JString, required = false,
                                 default = nil)
  if valid_600646 != nil:
    section.add "X-Amz-SignedHeaders", valid_600646
  var valid_600647 = header.getOrDefault("X-Amz-Credential")
  valid_600647 = validateParameter(valid_600647, JString, required = false,
                                 default = nil)
  if valid_600647 != nil:
    section.add "X-Amz-Credential", valid_600647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600649: Call_UntagResource_600637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ## 
  let valid = call_600649.validator(path, query, header, formData, body)
  let scheme = call_600649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600649.url(scheme.get, call_600649.host, call_600649.base,
                         call_600649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600649, url, valid)

proc call*(call_600650: Call_UntagResource_600637; body: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  var path_600651 = newJObject()
  var body_600652 = newJObject()
  if body != nil:
    body_600652 = body
  add(path_600651, "resourceArn", newJString(resourceArn))
  result = call_600650.call(path_600651, nil, nil, nil, body_600652)

var untagResource* = Call_UntagResource_600637(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/untag/{resourceArn}", validator: validate_UntagResource_600638,
    base: "/", url: url_UntagResource_600639, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
