
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Glue
## version: 2017-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Glue</fullname> <p>Defines the public endpoint for the AWS Glue service.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/glue/
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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "glue.ap-northeast-1.amazonaws.com", "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
                           "us-west-2": "glue.us-west-2.amazonaws.com",
                           "eu-west-2": "glue.eu-west-2.amazonaws.com", "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "glue.eu-central-1.amazonaws.com",
                           "us-east-2": "glue.us-east-2.amazonaws.com",
                           "us-east-1": "glue.us-east-1.amazonaws.com", "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "glue.ap-south-1.amazonaws.com",
                           "eu-north-1": "glue.eu-north-1.amazonaws.com", "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
                           "us-west-1": "glue.us-west-1.amazonaws.com",
                           "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "glue.eu-west-3.amazonaws.com",
                           "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "glue.sa-east-1.amazonaws.com",
                           "eu-west-1": "glue.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com", "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "glue.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
      "us-west-2": "glue.us-west-2.amazonaws.com",
      "eu-west-2": "glue.eu-west-2.amazonaws.com",
      "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
      "eu-central-1": "glue.eu-central-1.amazonaws.com",
      "us-east-2": "glue.us-east-2.amazonaws.com",
      "us-east-1": "glue.us-east-1.amazonaws.com",
      "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "glue.ap-south-1.amazonaws.com",
      "eu-north-1": "glue.eu-north-1.amazonaws.com",
      "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
      "us-west-1": "glue.us-west-1.amazonaws.com",
      "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
      "eu-west-3": "glue.eu-west-3.amazonaws.com",
      "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "glue.sa-east-1.amazonaws.com",
      "eu-west-1": "glue.eu-west-1.amazonaws.com",
      "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
      "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "glue"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCreatePartition_590703 = ref object of OpenApiRestCall_590364
proc url_BatchCreatePartition_590705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchCreatePartition_590704(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates one or more partitions in a batch operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590830 = header.getOrDefault("X-Amz-Target")
  valid_590830 = validateParameter(valid_590830, JString, required = true, default = newJString(
      "AWSGlue.BatchCreatePartition"))
  if valid_590830 != nil:
    section.add "X-Amz-Target", valid_590830
  var valid_590831 = header.getOrDefault("X-Amz-Signature")
  valid_590831 = validateParameter(valid_590831, JString, required = false,
                                 default = nil)
  if valid_590831 != nil:
    section.add "X-Amz-Signature", valid_590831
  var valid_590832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590832 = validateParameter(valid_590832, JString, required = false,
                                 default = nil)
  if valid_590832 != nil:
    section.add "X-Amz-Content-Sha256", valid_590832
  var valid_590833 = header.getOrDefault("X-Amz-Date")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Date", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Credential")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Credential", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Security-Token")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Security-Token", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Algorithm")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Algorithm", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-SignedHeaders", valid_590837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590861: Call_BatchCreatePartition_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_590861.validator(path, query, header, formData, body)
  let scheme = call_590861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590861.url(scheme.get, call_590861.host, call_590861.base,
                         call_590861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590861, url, valid)

proc call*(call_590932: Call_BatchCreatePartition_590703; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_590933 = newJObject()
  if body != nil:
    body_590933 = body
  result = call_590932.call(nil, nil, nil, nil, body_590933)

var batchCreatePartition* = Call_BatchCreatePartition_590703(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_590704, base: "/",
    url: url_BatchCreatePartition_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_590972 = ref object of OpenApiRestCall_590364
proc url_BatchDeleteConnection_590974(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteConnection_590973(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590975 = header.getOrDefault("X-Amz-Target")
  valid_590975 = validateParameter(valid_590975, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteConnection"))
  if valid_590975 != nil:
    section.add "X-Amz-Target", valid_590975
  var valid_590976 = header.getOrDefault("X-Amz-Signature")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Signature", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Content-Sha256", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Date")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Date", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Credential")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Credential", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Security-Token")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Security-Token", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Algorithm")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Algorithm", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-SignedHeaders", valid_590982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590984: Call_BatchDeleteConnection_590972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_590984.validator(path, query, header, formData, body)
  let scheme = call_590984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590984.url(scheme.get, call_590984.host, call_590984.base,
                         call_590984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590984, url, valid)

proc call*(call_590985: Call_BatchDeleteConnection_590972; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_590986 = newJObject()
  if body != nil:
    body_590986 = body
  result = call_590985.call(nil, nil, nil, nil, body_590986)

var batchDeleteConnection* = Call_BatchDeleteConnection_590972(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_590973, base: "/",
    url: url_BatchDeleteConnection_590974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_590987 = ref object of OpenApiRestCall_590364
proc url_BatchDeletePartition_590989(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeletePartition_590988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes one or more partitions in a batch operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590990 = header.getOrDefault("X-Amz-Target")
  valid_590990 = validateParameter(valid_590990, JString, required = true, default = newJString(
      "AWSGlue.BatchDeletePartition"))
  if valid_590990 != nil:
    section.add "X-Amz-Target", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Signature")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Signature", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Content-Sha256", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Date")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Date", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Credential")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Credential", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Security-Token")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Security-Token", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Algorithm")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Algorithm", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-SignedHeaders", valid_590997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590999: Call_BatchDeletePartition_590987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_590999.validator(path, query, header, formData, body)
  let scheme = call_590999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590999.url(scheme.get, call_590999.host, call_590999.base,
                         call_590999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590999, url, valid)

proc call*(call_591000: Call_BatchDeletePartition_590987; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_591001 = newJObject()
  if body != nil:
    body_591001 = body
  result = call_591000.call(nil, nil, nil, nil, body_591001)

var batchDeletePartition* = Call_BatchDeletePartition_590987(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_590988, base: "/",
    url: url_BatchDeletePartition_590989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_591002 = ref object of OpenApiRestCall_590364
proc url_BatchDeleteTable_591004(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteTable_591003(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591005 = header.getOrDefault("X-Amz-Target")
  valid_591005 = validateParameter(valid_591005, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTable"))
  if valid_591005 != nil:
    section.add "X-Amz-Target", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Signature")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Signature", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Content-Sha256", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Date")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Date", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Credential")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Credential", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Security-Token")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Security-Token", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Algorithm")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Algorithm", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-SignedHeaders", valid_591012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591014: Call_BatchDeleteTable_591002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_591014.validator(path, query, header, formData, body)
  let scheme = call_591014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591014.url(scheme.get, call_591014.host, call_591014.base,
                         call_591014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591014, url, valid)

proc call*(call_591015: Call_BatchDeleteTable_591002; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_591016 = newJObject()
  if body != nil:
    body_591016 = body
  result = call_591015.call(nil, nil, nil, nil, body_591016)

var batchDeleteTable* = Call_BatchDeleteTable_591002(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_591003, base: "/",
    url: url_BatchDeleteTable_591004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_591017 = ref object of OpenApiRestCall_590364
proc url_BatchDeleteTableVersion_591019(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteTableVersion_591018(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified batch of versions of a table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591020 = header.getOrDefault("X-Amz-Target")
  valid_591020 = validateParameter(valid_591020, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTableVersion"))
  if valid_591020 != nil:
    section.add "X-Amz-Target", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Signature")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Signature", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Content-Sha256", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Date")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Date", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Credential")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Credential", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Security-Token")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Security-Token", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Algorithm")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Algorithm", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-SignedHeaders", valid_591027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591029: Call_BatchDeleteTableVersion_591017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_591029.validator(path, query, header, formData, body)
  let scheme = call_591029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591029.url(scheme.get, call_591029.host, call_591029.base,
                         call_591029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591029, url, valid)

proc call*(call_591030: Call_BatchDeleteTableVersion_591017; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_591031 = newJObject()
  if body != nil:
    body_591031 = body
  result = call_591030.call(nil, nil, nil, nil, body_591031)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_591017(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_591018, base: "/",
    url: url_BatchDeleteTableVersion_591019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_591032 = ref object of OpenApiRestCall_590364
proc url_BatchGetCrawlers_591034(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetCrawlers_591033(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591035 = header.getOrDefault("X-Amz-Target")
  valid_591035 = validateParameter(valid_591035, JString, required = true, default = newJString(
      "AWSGlue.BatchGetCrawlers"))
  if valid_591035 != nil:
    section.add "X-Amz-Target", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Signature")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Signature", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Content-Sha256", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Date")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Date", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Credential")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Credential", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Security-Token")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Security-Token", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Algorithm")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Algorithm", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-SignedHeaders", valid_591042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591044: Call_BatchGetCrawlers_591032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_591044.validator(path, query, header, formData, body)
  let scheme = call_591044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591044.url(scheme.get, call_591044.host, call_591044.base,
                         call_591044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591044, url, valid)

proc call*(call_591045: Call_BatchGetCrawlers_591032; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_591046 = newJObject()
  if body != nil:
    body_591046 = body
  result = call_591045.call(nil, nil, nil, nil, body_591046)

var batchGetCrawlers* = Call_BatchGetCrawlers_591032(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_591033, base: "/",
    url: url_BatchGetCrawlers_591034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_591047 = ref object of OpenApiRestCall_590364
proc url_BatchGetDevEndpoints_591049(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetDevEndpoints_591048(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591050 = header.getOrDefault("X-Amz-Target")
  valid_591050 = validateParameter(valid_591050, JString, required = true, default = newJString(
      "AWSGlue.BatchGetDevEndpoints"))
  if valid_591050 != nil:
    section.add "X-Amz-Target", valid_591050
  var valid_591051 = header.getOrDefault("X-Amz-Signature")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Signature", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Content-Sha256", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Date")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Date", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Credential")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Credential", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Security-Token")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Security-Token", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Algorithm")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Algorithm", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-SignedHeaders", valid_591057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591059: Call_BatchGetDevEndpoints_591047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_591059.validator(path, query, header, formData, body)
  let scheme = call_591059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591059.url(scheme.get, call_591059.host, call_591059.base,
                         call_591059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591059, url, valid)

proc call*(call_591060: Call_BatchGetDevEndpoints_591047; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_591061 = newJObject()
  if body != nil:
    body_591061 = body
  result = call_591060.call(nil, nil, nil, nil, body_591061)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_591047(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_591048, base: "/",
    url: url_BatchGetDevEndpoints_591049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_591062 = ref object of OpenApiRestCall_590364
proc url_BatchGetJobs_591064(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetJobs_591063(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591065 = header.getOrDefault("X-Amz-Target")
  valid_591065 = validateParameter(valid_591065, JString, required = true,
                                 default = newJString("AWSGlue.BatchGetJobs"))
  if valid_591065 != nil:
    section.add "X-Amz-Target", valid_591065
  var valid_591066 = header.getOrDefault("X-Amz-Signature")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Signature", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Content-Sha256", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Date")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Date", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Credential")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Credential", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Security-Token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Security-Token", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Algorithm")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Algorithm", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-SignedHeaders", valid_591072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591074: Call_BatchGetJobs_591062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_591074.validator(path, query, header, formData, body)
  let scheme = call_591074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591074.url(scheme.get, call_591074.host, call_591074.base,
                         call_591074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591074, url, valid)

proc call*(call_591075: Call_BatchGetJobs_591062; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_591076 = newJObject()
  if body != nil:
    body_591076 = body
  result = call_591075.call(nil, nil, nil, nil, body_591076)

var batchGetJobs* = Call_BatchGetJobs_591062(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_591063, base: "/", url: url_BatchGetJobs_591064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_591077 = ref object of OpenApiRestCall_590364
proc url_BatchGetPartition_591079(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetPartition_591078(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves partitions in a batch request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591080 = header.getOrDefault("X-Amz-Target")
  valid_591080 = validateParameter(valid_591080, JString, required = true, default = newJString(
      "AWSGlue.BatchGetPartition"))
  if valid_591080 != nil:
    section.add "X-Amz-Target", valid_591080
  var valid_591081 = header.getOrDefault("X-Amz-Signature")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Signature", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Content-Sha256", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Date")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Date", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Credential")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Credential", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Security-Token")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Security-Token", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Algorithm")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Algorithm", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-SignedHeaders", valid_591087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591089: Call_BatchGetPartition_591077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_591089.validator(path, query, header, formData, body)
  let scheme = call_591089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591089.url(scheme.get, call_591089.host, call_591089.base,
                         call_591089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591089, url, valid)

proc call*(call_591090: Call_BatchGetPartition_591077; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_591091 = newJObject()
  if body != nil:
    body_591091 = body
  result = call_591090.call(nil, nil, nil, nil, body_591091)

var batchGetPartition* = Call_BatchGetPartition_591077(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_591078, base: "/",
    url: url_BatchGetPartition_591079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_591092 = ref object of OpenApiRestCall_590364
proc url_BatchGetTriggers_591094(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetTriggers_591093(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591095 = header.getOrDefault("X-Amz-Target")
  valid_591095 = validateParameter(valid_591095, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_591095 != nil:
    section.add "X-Amz-Target", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Signature")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Signature", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Content-Sha256", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Date")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Date", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Credential")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Credential", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Security-Token")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Security-Token", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Algorithm")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Algorithm", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-SignedHeaders", valid_591102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591104: Call_BatchGetTriggers_591092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_591104.validator(path, query, header, formData, body)
  let scheme = call_591104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591104.url(scheme.get, call_591104.host, call_591104.base,
                         call_591104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591104, url, valid)

proc call*(call_591105: Call_BatchGetTriggers_591092; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_591106 = newJObject()
  if body != nil:
    body_591106 = body
  result = call_591105.call(nil, nil, nil, nil, body_591106)

var batchGetTriggers* = Call_BatchGetTriggers_591092(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_591093, base: "/",
    url: url_BatchGetTriggers_591094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_591107 = ref object of OpenApiRestCall_590364
proc url_BatchGetWorkflows_591109(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetWorkflows_591108(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591110 = header.getOrDefault("X-Amz-Target")
  valid_591110 = validateParameter(valid_591110, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_591110 != nil:
    section.add "X-Amz-Target", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Signature")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Signature", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Content-Sha256", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Date")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Date", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Credential")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Credential", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Security-Token")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Security-Token", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-Algorithm")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-Algorithm", valid_591116
  var valid_591117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-SignedHeaders", valid_591117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591119: Call_BatchGetWorkflows_591107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_591119.validator(path, query, header, formData, body)
  let scheme = call_591119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591119.url(scheme.get, call_591119.host, call_591119.base,
                         call_591119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591119, url, valid)

proc call*(call_591120: Call_BatchGetWorkflows_591107; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_591121 = newJObject()
  if body != nil:
    body_591121 = body
  result = call_591120.call(nil, nil, nil, nil, body_591121)

var batchGetWorkflows* = Call_BatchGetWorkflows_591107(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_591108, base: "/",
    url: url_BatchGetWorkflows_591109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_591122 = ref object of OpenApiRestCall_590364
proc url_BatchStopJobRun_591124(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchStopJobRun_591123(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Stops one or more job runs for a specified job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591125 = header.getOrDefault("X-Amz-Target")
  valid_591125 = validateParameter(valid_591125, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_591125 != nil:
    section.add "X-Amz-Target", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Signature")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Signature", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Content-Sha256", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Date")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Date", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Credential")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Credential", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Security-Token")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Security-Token", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Algorithm")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Algorithm", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-SignedHeaders", valid_591132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591134: Call_BatchStopJobRun_591122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_591134.validator(path, query, header, formData, body)
  let scheme = call_591134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591134.url(scheme.get, call_591134.host, call_591134.base,
                         call_591134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591134, url, valid)

proc call*(call_591135: Call_BatchStopJobRun_591122; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_591136 = newJObject()
  if body != nil:
    body_591136 = body
  result = call_591135.call(nil, nil, nil, nil, body_591136)

var batchStopJobRun* = Call_BatchStopJobRun_591122(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_591123, base: "/", url: url_BatchStopJobRun_591124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_591137 = ref object of OpenApiRestCall_590364
proc url_CancelMLTaskRun_591139(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelMLTaskRun_591138(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591140 = header.getOrDefault("X-Amz-Target")
  valid_591140 = validateParameter(valid_591140, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_591140 != nil:
    section.add "X-Amz-Target", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Signature")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Signature", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Content-Sha256", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Date")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Date", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Credential")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Credential", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Security-Token")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Security-Token", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-Algorithm")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-Algorithm", valid_591146
  var valid_591147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591147 = validateParameter(valid_591147, JString, required = false,
                                 default = nil)
  if valid_591147 != nil:
    section.add "X-Amz-SignedHeaders", valid_591147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591149: Call_CancelMLTaskRun_591137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_591149.validator(path, query, header, formData, body)
  let scheme = call_591149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591149.url(scheme.get, call_591149.host, call_591149.base,
                         call_591149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591149, url, valid)

proc call*(call_591150: Call_CancelMLTaskRun_591137; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_591151 = newJObject()
  if body != nil:
    body_591151 = body
  result = call_591150.call(nil, nil, nil, nil, body_591151)

var cancelMLTaskRun* = Call_CancelMLTaskRun_591137(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_591138, base: "/", url: url_CancelMLTaskRun_591139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_591152 = ref object of OpenApiRestCall_590364
proc url_CreateClassifier_591154(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateClassifier_591153(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591155 = header.getOrDefault("X-Amz-Target")
  valid_591155 = validateParameter(valid_591155, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_591155 != nil:
    section.add "X-Amz-Target", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Signature")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Signature", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Content-Sha256", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Date")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Date", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Credential")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Credential", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Security-Token")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Security-Token", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-Algorithm")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Algorithm", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-SignedHeaders", valid_591162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591164: Call_CreateClassifier_591152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_591164.validator(path, query, header, formData, body)
  let scheme = call_591164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591164.url(scheme.get, call_591164.host, call_591164.base,
                         call_591164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591164, url, valid)

proc call*(call_591165: Call_CreateClassifier_591152; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_591166 = newJObject()
  if body != nil:
    body_591166 = body
  result = call_591165.call(nil, nil, nil, nil, body_591166)

var createClassifier* = Call_CreateClassifier_591152(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_591153, base: "/",
    url: url_CreateClassifier_591154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_591167 = ref object of OpenApiRestCall_590364
proc url_CreateConnection_591169(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConnection_591168(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a connection definition in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591170 = header.getOrDefault("X-Amz-Target")
  valid_591170 = validateParameter(valid_591170, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_591170 != nil:
    section.add "X-Amz-Target", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Signature")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Signature", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Content-Sha256", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Date")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Date", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Credential")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Credential", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Security-Token")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Security-Token", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Algorithm")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Algorithm", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-SignedHeaders", valid_591177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591179: Call_CreateConnection_591167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_591179.validator(path, query, header, formData, body)
  let scheme = call_591179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591179.url(scheme.get, call_591179.host, call_591179.base,
                         call_591179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591179, url, valid)

proc call*(call_591180: Call_CreateConnection_591167; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_591181 = newJObject()
  if body != nil:
    body_591181 = body
  result = call_591180.call(nil, nil, nil, nil, body_591181)

var createConnection* = Call_CreateConnection_591167(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_591168, base: "/",
    url: url_CreateConnection_591169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_591182 = ref object of OpenApiRestCall_590364
proc url_CreateCrawler_591184(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCrawler_591183(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591185 = header.getOrDefault("X-Amz-Target")
  valid_591185 = validateParameter(valid_591185, JString, required = true,
                                 default = newJString("AWSGlue.CreateCrawler"))
  if valid_591185 != nil:
    section.add "X-Amz-Target", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Signature")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Signature", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Content-Sha256", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Date")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Date", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Credential")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Credential", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Security-Token")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Security-Token", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Algorithm")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Algorithm", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-SignedHeaders", valid_591192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591194: Call_CreateCrawler_591182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_591194.validator(path, query, header, formData, body)
  let scheme = call_591194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591194.url(scheme.get, call_591194.host, call_591194.base,
                         call_591194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591194, url, valid)

proc call*(call_591195: Call_CreateCrawler_591182; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_591196 = newJObject()
  if body != nil:
    body_591196 = body
  result = call_591195.call(nil, nil, nil, nil, body_591196)

var createCrawler* = Call_CreateCrawler_591182(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_591183, base: "/", url: url_CreateCrawler_591184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_591197 = ref object of OpenApiRestCall_590364
proc url_CreateDatabase_591199(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDatabase_591198(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new database in a Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591200 = header.getOrDefault("X-Amz-Target")
  valid_591200 = validateParameter(valid_591200, JString, required = true,
                                 default = newJString("AWSGlue.CreateDatabase"))
  if valid_591200 != nil:
    section.add "X-Amz-Target", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-Signature")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Signature", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Content-Sha256", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-Date")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-Date", valid_591203
  var valid_591204 = header.getOrDefault("X-Amz-Credential")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "X-Amz-Credential", valid_591204
  var valid_591205 = header.getOrDefault("X-Amz-Security-Token")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "X-Amz-Security-Token", valid_591205
  var valid_591206 = header.getOrDefault("X-Amz-Algorithm")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Algorithm", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-SignedHeaders", valid_591207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591209: Call_CreateDatabase_591197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_591209.validator(path, query, header, formData, body)
  let scheme = call_591209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591209.url(scheme.get, call_591209.host, call_591209.base,
                         call_591209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591209, url, valid)

proc call*(call_591210: Call_CreateDatabase_591197; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_591211 = newJObject()
  if body != nil:
    body_591211 = body
  result = call_591210.call(nil, nil, nil, nil, body_591211)

var createDatabase* = Call_CreateDatabase_591197(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_591198, base: "/", url: url_CreateDatabase_591199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_591212 = ref object of OpenApiRestCall_590364
proc url_CreateDevEndpoint_591214(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDevEndpoint_591213(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a new development endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591215 = header.getOrDefault("X-Amz-Target")
  valid_591215 = validateParameter(valid_591215, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_591215 != nil:
    section.add "X-Amz-Target", valid_591215
  var valid_591216 = header.getOrDefault("X-Amz-Signature")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "X-Amz-Signature", valid_591216
  var valid_591217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591217 = validateParameter(valid_591217, JString, required = false,
                                 default = nil)
  if valid_591217 != nil:
    section.add "X-Amz-Content-Sha256", valid_591217
  var valid_591218 = header.getOrDefault("X-Amz-Date")
  valid_591218 = validateParameter(valid_591218, JString, required = false,
                                 default = nil)
  if valid_591218 != nil:
    section.add "X-Amz-Date", valid_591218
  var valid_591219 = header.getOrDefault("X-Amz-Credential")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-Credential", valid_591219
  var valid_591220 = header.getOrDefault("X-Amz-Security-Token")
  valid_591220 = validateParameter(valid_591220, JString, required = false,
                                 default = nil)
  if valid_591220 != nil:
    section.add "X-Amz-Security-Token", valid_591220
  var valid_591221 = header.getOrDefault("X-Amz-Algorithm")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "X-Amz-Algorithm", valid_591221
  var valid_591222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-SignedHeaders", valid_591222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591224: Call_CreateDevEndpoint_591212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_591224.validator(path, query, header, formData, body)
  let scheme = call_591224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591224.url(scheme.get, call_591224.host, call_591224.base,
                         call_591224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591224, url, valid)

proc call*(call_591225: Call_CreateDevEndpoint_591212; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_591226 = newJObject()
  if body != nil:
    body_591226 = body
  result = call_591225.call(nil, nil, nil, nil, body_591226)

var createDevEndpoint* = Call_CreateDevEndpoint_591212(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_591213, base: "/",
    url: url_CreateDevEndpoint_591214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_591227 = ref object of OpenApiRestCall_590364
proc url_CreateJob_591229(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_591228(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591230 = header.getOrDefault("X-Amz-Target")
  valid_591230 = validateParameter(valid_591230, JString, required = true,
                                 default = newJString("AWSGlue.CreateJob"))
  if valid_591230 != nil:
    section.add "X-Amz-Target", valid_591230
  var valid_591231 = header.getOrDefault("X-Amz-Signature")
  valid_591231 = validateParameter(valid_591231, JString, required = false,
                                 default = nil)
  if valid_591231 != nil:
    section.add "X-Amz-Signature", valid_591231
  var valid_591232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Content-Sha256", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-Date")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-Date", valid_591233
  var valid_591234 = header.getOrDefault("X-Amz-Credential")
  valid_591234 = validateParameter(valid_591234, JString, required = false,
                                 default = nil)
  if valid_591234 != nil:
    section.add "X-Amz-Credential", valid_591234
  var valid_591235 = header.getOrDefault("X-Amz-Security-Token")
  valid_591235 = validateParameter(valid_591235, JString, required = false,
                                 default = nil)
  if valid_591235 != nil:
    section.add "X-Amz-Security-Token", valid_591235
  var valid_591236 = header.getOrDefault("X-Amz-Algorithm")
  valid_591236 = validateParameter(valid_591236, JString, required = false,
                                 default = nil)
  if valid_591236 != nil:
    section.add "X-Amz-Algorithm", valid_591236
  var valid_591237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591237 = validateParameter(valid_591237, JString, required = false,
                                 default = nil)
  if valid_591237 != nil:
    section.add "X-Amz-SignedHeaders", valid_591237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591239: Call_CreateJob_591227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_591239.validator(path, query, header, formData, body)
  let scheme = call_591239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591239.url(scheme.get, call_591239.host, call_591239.base,
                         call_591239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591239, url, valid)

proc call*(call_591240: Call_CreateJob_591227; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_591241 = newJObject()
  if body != nil:
    body_591241 = body
  result = call_591240.call(nil, nil, nil, nil, body_591241)

var createJob* = Call_CreateJob_591227(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                    validator: validate_CreateJob_591228,
                                    base: "/", url: url_CreateJob_591229,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_591242 = ref object of OpenApiRestCall_590364
proc url_CreateMLTransform_591244(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMLTransform_591243(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591245 = header.getOrDefault("X-Amz-Target")
  valid_591245 = validateParameter(valid_591245, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_591245 != nil:
    section.add "X-Amz-Target", valid_591245
  var valid_591246 = header.getOrDefault("X-Amz-Signature")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Signature", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-Content-Sha256", valid_591247
  var valid_591248 = header.getOrDefault("X-Amz-Date")
  valid_591248 = validateParameter(valid_591248, JString, required = false,
                                 default = nil)
  if valid_591248 != nil:
    section.add "X-Amz-Date", valid_591248
  var valid_591249 = header.getOrDefault("X-Amz-Credential")
  valid_591249 = validateParameter(valid_591249, JString, required = false,
                                 default = nil)
  if valid_591249 != nil:
    section.add "X-Amz-Credential", valid_591249
  var valid_591250 = header.getOrDefault("X-Amz-Security-Token")
  valid_591250 = validateParameter(valid_591250, JString, required = false,
                                 default = nil)
  if valid_591250 != nil:
    section.add "X-Amz-Security-Token", valid_591250
  var valid_591251 = header.getOrDefault("X-Amz-Algorithm")
  valid_591251 = validateParameter(valid_591251, JString, required = false,
                                 default = nil)
  if valid_591251 != nil:
    section.add "X-Amz-Algorithm", valid_591251
  var valid_591252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591252 = validateParameter(valid_591252, JString, required = false,
                                 default = nil)
  if valid_591252 != nil:
    section.add "X-Amz-SignedHeaders", valid_591252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591254: Call_CreateMLTransform_591242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_591254.validator(path, query, header, formData, body)
  let scheme = call_591254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591254.url(scheme.get, call_591254.host, call_591254.base,
                         call_591254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591254, url, valid)

proc call*(call_591255: Call_CreateMLTransform_591242; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_591256 = newJObject()
  if body != nil:
    body_591256 = body
  result = call_591255.call(nil, nil, nil, nil, body_591256)

var createMLTransform* = Call_CreateMLTransform_591242(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_591243, base: "/",
    url: url_CreateMLTransform_591244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_591257 = ref object of OpenApiRestCall_590364
proc url_CreatePartition_591259(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePartition_591258(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new partition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591260 = header.getOrDefault("X-Amz-Target")
  valid_591260 = validateParameter(valid_591260, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_591260 != nil:
    section.add "X-Amz-Target", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Signature")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Signature", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-Content-Sha256", valid_591262
  var valid_591263 = header.getOrDefault("X-Amz-Date")
  valid_591263 = validateParameter(valid_591263, JString, required = false,
                                 default = nil)
  if valid_591263 != nil:
    section.add "X-Amz-Date", valid_591263
  var valid_591264 = header.getOrDefault("X-Amz-Credential")
  valid_591264 = validateParameter(valid_591264, JString, required = false,
                                 default = nil)
  if valid_591264 != nil:
    section.add "X-Amz-Credential", valid_591264
  var valid_591265 = header.getOrDefault("X-Amz-Security-Token")
  valid_591265 = validateParameter(valid_591265, JString, required = false,
                                 default = nil)
  if valid_591265 != nil:
    section.add "X-Amz-Security-Token", valid_591265
  var valid_591266 = header.getOrDefault("X-Amz-Algorithm")
  valid_591266 = validateParameter(valid_591266, JString, required = false,
                                 default = nil)
  if valid_591266 != nil:
    section.add "X-Amz-Algorithm", valid_591266
  var valid_591267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591267 = validateParameter(valid_591267, JString, required = false,
                                 default = nil)
  if valid_591267 != nil:
    section.add "X-Amz-SignedHeaders", valid_591267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591269: Call_CreatePartition_591257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_591269.validator(path, query, header, formData, body)
  let scheme = call_591269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591269.url(scheme.get, call_591269.host, call_591269.base,
                         call_591269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591269, url, valid)

proc call*(call_591270: Call_CreatePartition_591257; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_591271 = newJObject()
  if body != nil:
    body_591271 = body
  result = call_591270.call(nil, nil, nil, nil, body_591271)

var createPartition* = Call_CreatePartition_591257(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_591258, base: "/", url: url_CreatePartition_591259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_591272 = ref object of OpenApiRestCall_590364
proc url_CreateScript_591274(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateScript_591273(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591275 = header.getOrDefault("X-Amz-Target")
  valid_591275 = validateParameter(valid_591275, JString, required = true,
                                 default = newJString("AWSGlue.CreateScript"))
  if valid_591275 != nil:
    section.add "X-Amz-Target", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Signature")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Signature", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Content-Sha256", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Date")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Date", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-Credential")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-Credential", valid_591279
  var valid_591280 = header.getOrDefault("X-Amz-Security-Token")
  valid_591280 = validateParameter(valid_591280, JString, required = false,
                                 default = nil)
  if valid_591280 != nil:
    section.add "X-Amz-Security-Token", valid_591280
  var valid_591281 = header.getOrDefault("X-Amz-Algorithm")
  valid_591281 = validateParameter(valid_591281, JString, required = false,
                                 default = nil)
  if valid_591281 != nil:
    section.add "X-Amz-Algorithm", valid_591281
  var valid_591282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591282 = validateParameter(valid_591282, JString, required = false,
                                 default = nil)
  if valid_591282 != nil:
    section.add "X-Amz-SignedHeaders", valid_591282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591284: Call_CreateScript_591272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_591284.validator(path, query, header, formData, body)
  let scheme = call_591284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591284.url(scheme.get, call_591284.host, call_591284.base,
                         call_591284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591284, url, valid)

proc call*(call_591285: Call_CreateScript_591272; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_591286 = newJObject()
  if body != nil:
    body_591286 = body
  result = call_591285.call(nil, nil, nil, nil, body_591286)

var createScript* = Call_CreateScript_591272(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_591273, base: "/", url: url_CreateScript_591274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_591287 = ref object of OpenApiRestCall_590364
proc url_CreateSecurityConfiguration_591289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSecurityConfiguration_591288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591290 = header.getOrDefault("X-Amz-Target")
  valid_591290 = validateParameter(valid_591290, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_591290 != nil:
    section.add "X-Amz-Target", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Signature")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Signature", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Content-Sha256", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Date")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Date", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-Credential")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-Credential", valid_591294
  var valid_591295 = header.getOrDefault("X-Amz-Security-Token")
  valid_591295 = validateParameter(valid_591295, JString, required = false,
                                 default = nil)
  if valid_591295 != nil:
    section.add "X-Amz-Security-Token", valid_591295
  var valid_591296 = header.getOrDefault("X-Amz-Algorithm")
  valid_591296 = validateParameter(valid_591296, JString, required = false,
                                 default = nil)
  if valid_591296 != nil:
    section.add "X-Amz-Algorithm", valid_591296
  var valid_591297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591297 = validateParameter(valid_591297, JString, required = false,
                                 default = nil)
  if valid_591297 != nil:
    section.add "X-Amz-SignedHeaders", valid_591297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591299: Call_CreateSecurityConfiguration_591287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_591299.validator(path, query, header, formData, body)
  let scheme = call_591299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591299.url(scheme.get, call_591299.host, call_591299.base,
                         call_591299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591299, url, valid)

proc call*(call_591300: Call_CreateSecurityConfiguration_591287; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_591301 = newJObject()
  if body != nil:
    body_591301 = body
  result = call_591300.call(nil, nil, nil, nil, body_591301)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_591287(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_591288, base: "/",
    url: url_CreateSecurityConfiguration_591289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_591302 = ref object of OpenApiRestCall_590364
proc url_CreateTable_591304(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTable_591303(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new table definition in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591305 = header.getOrDefault("X-Amz-Target")
  valid_591305 = validateParameter(valid_591305, JString, required = true,
                                 default = newJString("AWSGlue.CreateTable"))
  if valid_591305 != nil:
    section.add "X-Amz-Target", valid_591305
  var valid_591306 = header.getOrDefault("X-Amz-Signature")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amz-Signature", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Content-Sha256", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-Date")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Date", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-Credential")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-Credential", valid_591309
  var valid_591310 = header.getOrDefault("X-Amz-Security-Token")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-Security-Token", valid_591310
  var valid_591311 = header.getOrDefault("X-Amz-Algorithm")
  valid_591311 = validateParameter(valid_591311, JString, required = false,
                                 default = nil)
  if valid_591311 != nil:
    section.add "X-Amz-Algorithm", valid_591311
  var valid_591312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591312 = validateParameter(valid_591312, JString, required = false,
                                 default = nil)
  if valid_591312 != nil:
    section.add "X-Amz-SignedHeaders", valid_591312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591314: Call_CreateTable_591302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_591314.validator(path, query, header, formData, body)
  let scheme = call_591314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591314.url(scheme.get, call_591314.host, call_591314.base,
                         call_591314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591314, url, valid)

proc call*(call_591315: Call_CreateTable_591302; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_591316 = newJObject()
  if body != nil:
    body_591316 = body
  result = call_591315.call(nil, nil, nil, nil, body_591316)

var createTable* = Call_CreateTable_591302(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateTable",
                                        validator: validate_CreateTable_591303,
                                        base: "/", url: url_CreateTable_591304,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_591317 = ref object of OpenApiRestCall_590364
proc url_CreateTrigger_591319(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTrigger_591318(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new trigger.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591320 = header.getOrDefault("X-Amz-Target")
  valid_591320 = validateParameter(valid_591320, JString, required = true,
                                 default = newJString("AWSGlue.CreateTrigger"))
  if valid_591320 != nil:
    section.add "X-Amz-Target", valid_591320
  var valid_591321 = header.getOrDefault("X-Amz-Signature")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-Signature", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Content-Sha256", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Date")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Date", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-Credential")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-Credential", valid_591324
  var valid_591325 = header.getOrDefault("X-Amz-Security-Token")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "X-Amz-Security-Token", valid_591325
  var valid_591326 = header.getOrDefault("X-Amz-Algorithm")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-Algorithm", valid_591326
  var valid_591327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591327 = validateParameter(valid_591327, JString, required = false,
                                 default = nil)
  if valid_591327 != nil:
    section.add "X-Amz-SignedHeaders", valid_591327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591329: Call_CreateTrigger_591317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_591329.validator(path, query, header, formData, body)
  let scheme = call_591329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591329.url(scheme.get, call_591329.host, call_591329.base,
                         call_591329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591329, url, valid)

proc call*(call_591330: Call_CreateTrigger_591317; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_591331 = newJObject()
  if body != nil:
    body_591331 = body
  result = call_591330.call(nil, nil, nil, nil, body_591331)

var createTrigger* = Call_CreateTrigger_591317(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_591318, base: "/", url: url_CreateTrigger_591319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_591332 = ref object of OpenApiRestCall_590364
proc url_CreateUserDefinedFunction_591334(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUserDefinedFunction_591333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new function definition in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591335 = header.getOrDefault("X-Amz-Target")
  valid_591335 = validateParameter(valid_591335, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_591335 != nil:
    section.add "X-Amz-Target", valid_591335
  var valid_591336 = header.getOrDefault("X-Amz-Signature")
  valid_591336 = validateParameter(valid_591336, JString, required = false,
                                 default = nil)
  if valid_591336 != nil:
    section.add "X-Amz-Signature", valid_591336
  var valid_591337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591337 = validateParameter(valid_591337, JString, required = false,
                                 default = nil)
  if valid_591337 != nil:
    section.add "X-Amz-Content-Sha256", valid_591337
  var valid_591338 = header.getOrDefault("X-Amz-Date")
  valid_591338 = validateParameter(valid_591338, JString, required = false,
                                 default = nil)
  if valid_591338 != nil:
    section.add "X-Amz-Date", valid_591338
  var valid_591339 = header.getOrDefault("X-Amz-Credential")
  valid_591339 = validateParameter(valid_591339, JString, required = false,
                                 default = nil)
  if valid_591339 != nil:
    section.add "X-Amz-Credential", valid_591339
  var valid_591340 = header.getOrDefault("X-Amz-Security-Token")
  valid_591340 = validateParameter(valid_591340, JString, required = false,
                                 default = nil)
  if valid_591340 != nil:
    section.add "X-Amz-Security-Token", valid_591340
  var valid_591341 = header.getOrDefault("X-Amz-Algorithm")
  valid_591341 = validateParameter(valid_591341, JString, required = false,
                                 default = nil)
  if valid_591341 != nil:
    section.add "X-Amz-Algorithm", valid_591341
  var valid_591342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591342 = validateParameter(valid_591342, JString, required = false,
                                 default = nil)
  if valid_591342 != nil:
    section.add "X-Amz-SignedHeaders", valid_591342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591344: Call_CreateUserDefinedFunction_591332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_591344.validator(path, query, header, formData, body)
  let scheme = call_591344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591344.url(scheme.get, call_591344.host, call_591344.base,
                         call_591344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591344, url, valid)

proc call*(call_591345: Call_CreateUserDefinedFunction_591332; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_591346 = newJObject()
  if body != nil:
    body_591346 = body
  result = call_591345.call(nil, nil, nil, nil, body_591346)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_591332(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_591333, base: "/",
    url: url_CreateUserDefinedFunction_591334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_591347 = ref object of OpenApiRestCall_590364
proc url_CreateWorkflow_591349(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkflow_591348(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591350 = header.getOrDefault("X-Amz-Target")
  valid_591350 = validateParameter(valid_591350, JString, required = true,
                                 default = newJString("AWSGlue.CreateWorkflow"))
  if valid_591350 != nil:
    section.add "X-Amz-Target", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-Signature")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-Signature", valid_591351
  var valid_591352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591352 = validateParameter(valid_591352, JString, required = false,
                                 default = nil)
  if valid_591352 != nil:
    section.add "X-Amz-Content-Sha256", valid_591352
  var valid_591353 = header.getOrDefault("X-Amz-Date")
  valid_591353 = validateParameter(valid_591353, JString, required = false,
                                 default = nil)
  if valid_591353 != nil:
    section.add "X-Amz-Date", valid_591353
  var valid_591354 = header.getOrDefault("X-Amz-Credential")
  valid_591354 = validateParameter(valid_591354, JString, required = false,
                                 default = nil)
  if valid_591354 != nil:
    section.add "X-Amz-Credential", valid_591354
  var valid_591355 = header.getOrDefault("X-Amz-Security-Token")
  valid_591355 = validateParameter(valid_591355, JString, required = false,
                                 default = nil)
  if valid_591355 != nil:
    section.add "X-Amz-Security-Token", valid_591355
  var valid_591356 = header.getOrDefault("X-Amz-Algorithm")
  valid_591356 = validateParameter(valid_591356, JString, required = false,
                                 default = nil)
  if valid_591356 != nil:
    section.add "X-Amz-Algorithm", valid_591356
  var valid_591357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591357 = validateParameter(valid_591357, JString, required = false,
                                 default = nil)
  if valid_591357 != nil:
    section.add "X-Amz-SignedHeaders", valid_591357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591359: Call_CreateWorkflow_591347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_591359.validator(path, query, header, formData, body)
  let scheme = call_591359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591359.url(scheme.get, call_591359.host, call_591359.base,
                         call_591359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591359, url, valid)

proc call*(call_591360: Call_CreateWorkflow_591347; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_591361 = newJObject()
  if body != nil:
    body_591361 = body
  result = call_591360.call(nil, nil, nil, nil, body_591361)

var createWorkflow* = Call_CreateWorkflow_591347(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_591348, base: "/", url: url_CreateWorkflow_591349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_591362 = ref object of OpenApiRestCall_590364
proc url_DeleteClassifier_591364(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteClassifier_591363(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Removes a classifier from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591365 = header.getOrDefault("X-Amz-Target")
  valid_591365 = validateParameter(valid_591365, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_591365 != nil:
    section.add "X-Amz-Target", valid_591365
  var valid_591366 = header.getOrDefault("X-Amz-Signature")
  valid_591366 = validateParameter(valid_591366, JString, required = false,
                                 default = nil)
  if valid_591366 != nil:
    section.add "X-Amz-Signature", valid_591366
  var valid_591367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "X-Amz-Content-Sha256", valid_591367
  var valid_591368 = header.getOrDefault("X-Amz-Date")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = nil)
  if valid_591368 != nil:
    section.add "X-Amz-Date", valid_591368
  var valid_591369 = header.getOrDefault("X-Amz-Credential")
  valid_591369 = validateParameter(valid_591369, JString, required = false,
                                 default = nil)
  if valid_591369 != nil:
    section.add "X-Amz-Credential", valid_591369
  var valid_591370 = header.getOrDefault("X-Amz-Security-Token")
  valid_591370 = validateParameter(valid_591370, JString, required = false,
                                 default = nil)
  if valid_591370 != nil:
    section.add "X-Amz-Security-Token", valid_591370
  var valid_591371 = header.getOrDefault("X-Amz-Algorithm")
  valid_591371 = validateParameter(valid_591371, JString, required = false,
                                 default = nil)
  if valid_591371 != nil:
    section.add "X-Amz-Algorithm", valid_591371
  var valid_591372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591372 = validateParameter(valid_591372, JString, required = false,
                                 default = nil)
  if valid_591372 != nil:
    section.add "X-Amz-SignedHeaders", valid_591372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591374: Call_DeleteClassifier_591362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_591374.validator(path, query, header, formData, body)
  let scheme = call_591374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591374.url(scheme.get, call_591374.host, call_591374.base,
                         call_591374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591374, url, valid)

proc call*(call_591375: Call_DeleteClassifier_591362; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_591376 = newJObject()
  if body != nil:
    body_591376 = body
  result = call_591375.call(nil, nil, nil, nil, body_591376)

var deleteClassifier* = Call_DeleteClassifier_591362(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_591363, base: "/",
    url: url_DeleteClassifier_591364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_591377 = ref object of OpenApiRestCall_590364
proc url_DeleteConnection_591379(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConnection_591378(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a connection from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591380 = header.getOrDefault("X-Amz-Target")
  valid_591380 = validateParameter(valid_591380, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_591380 != nil:
    section.add "X-Amz-Target", valid_591380
  var valid_591381 = header.getOrDefault("X-Amz-Signature")
  valid_591381 = validateParameter(valid_591381, JString, required = false,
                                 default = nil)
  if valid_591381 != nil:
    section.add "X-Amz-Signature", valid_591381
  var valid_591382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591382 = validateParameter(valid_591382, JString, required = false,
                                 default = nil)
  if valid_591382 != nil:
    section.add "X-Amz-Content-Sha256", valid_591382
  var valid_591383 = header.getOrDefault("X-Amz-Date")
  valid_591383 = validateParameter(valid_591383, JString, required = false,
                                 default = nil)
  if valid_591383 != nil:
    section.add "X-Amz-Date", valid_591383
  var valid_591384 = header.getOrDefault("X-Amz-Credential")
  valid_591384 = validateParameter(valid_591384, JString, required = false,
                                 default = nil)
  if valid_591384 != nil:
    section.add "X-Amz-Credential", valid_591384
  var valid_591385 = header.getOrDefault("X-Amz-Security-Token")
  valid_591385 = validateParameter(valid_591385, JString, required = false,
                                 default = nil)
  if valid_591385 != nil:
    section.add "X-Amz-Security-Token", valid_591385
  var valid_591386 = header.getOrDefault("X-Amz-Algorithm")
  valid_591386 = validateParameter(valid_591386, JString, required = false,
                                 default = nil)
  if valid_591386 != nil:
    section.add "X-Amz-Algorithm", valid_591386
  var valid_591387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591387 = validateParameter(valid_591387, JString, required = false,
                                 default = nil)
  if valid_591387 != nil:
    section.add "X-Amz-SignedHeaders", valid_591387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591389: Call_DeleteConnection_591377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_591389.validator(path, query, header, formData, body)
  let scheme = call_591389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591389.url(scheme.get, call_591389.host, call_591389.base,
                         call_591389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591389, url, valid)

proc call*(call_591390: Call_DeleteConnection_591377; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_591391 = newJObject()
  if body != nil:
    body_591391 = body
  result = call_591390.call(nil, nil, nil, nil, body_591391)

var deleteConnection* = Call_DeleteConnection_591377(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_591378, base: "/",
    url: url_DeleteConnection_591379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_591392 = ref object of OpenApiRestCall_590364
proc url_DeleteCrawler_591394(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCrawler_591393(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591395 = header.getOrDefault("X-Amz-Target")
  valid_591395 = validateParameter(valid_591395, JString, required = true,
                                 default = newJString("AWSGlue.DeleteCrawler"))
  if valid_591395 != nil:
    section.add "X-Amz-Target", valid_591395
  var valid_591396 = header.getOrDefault("X-Amz-Signature")
  valid_591396 = validateParameter(valid_591396, JString, required = false,
                                 default = nil)
  if valid_591396 != nil:
    section.add "X-Amz-Signature", valid_591396
  var valid_591397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591397 = validateParameter(valid_591397, JString, required = false,
                                 default = nil)
  if valid_591397 != nil:
    section.add "X-Amz-Content-Sha256", valid_591397
  var valid_591398 = header.getOrDefault("X-Amz-Date")
  valid_591398 = validateParameter(valid_591398, JString, required = false,
                                 default = nil)
  if valid_591398 != nil:
    section.add "X-Amz-Date", valid_591398
  var valid_591399 = header.getOrDefault("X-Amz-Credential")
  valid_591399 = validateParameter(valid_591399, JString, required = false,
                                 default = nil)
  if valid_591399 != nil:
    section.add "X-Amz-Credential", valid_591399
  var valid_591400 = header.getOrDefault("X-Amz-Security-Token")
  valid_591400 = validateParameter(valid_591400, JString, required = false,
                                 default = nil)
  if valid_591400 != nil:
    section.add "X-Amz-Security-Token", valid_591400
  var valid_591401 = header.getOrDefault("X-Amz-Algorithm")
  valid_591401 = validateParameter(valid_591401, JString, required = false,
                                 default = nil)
  if valid_591401 != nil:
    section.add "X-Amz-Algorithm", valid_591401
  var valid_591402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591402 = validateParameter(valid_591402, JString, required = false,
                                 default = nil)
  if valid_591402 != nil:
    section.add "X-Amz-SignedHeaders", valid_591402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591404: Call_DeleteCrawler_591392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_591404.validator(path, query, header, formData, body)
  let scheme = call_591404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591404.url(scheme.get, call_591404.host, call_591404.base,
                         call_591404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591404, url, valid)

proc call*(call_591405: Call_DeleteCrawler_591392; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_591406 = newJObject()
  if body != nil:
    body_591406 = body
  result = call_591405.call(nil, nil, nil, nil, body_591406)

var deleteCrawler* = Call_DeleteCrawler_591392(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_591393, base: "/", url: url_DeleteCrawler_591394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_591407 = ref object of OpenApiRestCall_590364
proc url_DeleteDatabase_591409(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDatabase_591408(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591410 = header.getOrDefault("X-Amz-Target")
  valid_591410 = validateParameter(valid_591410, JString, required = true,
                                 default = newJString("AWSGlue.DeleteDatabase"))
  if valid_591410 != nil:
    section.add "X-Amz-Target", valid_591410
  var valid_591411 = header.getOrDefault("X-Amz-Signature")
  valid_591411 = validateParameter(valid_591411, JString, required = false,
                                 default = nil)
  if valid_591411 != nil:
    section.add "X-Amz-Signature", valid_591411
  var valid_591412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591412 = validateParameter(valid_591412, JString, required = false,
                                 default = nil)
  if valid_591412 != nil:
    section.add "X-Amz-Content-Sha256", valid_591412
  var valid_591413 = header.getOrDefault("X-Amz-Date")
  valid_591413 = validateParameter(valid_591413, JString, required = false,
                                 default = nil)
  if valid_591413 != nil:
    section.add "X-Amz-Date", valid_591413
  var valid_591414 = header.getOrDefault("X-Amz-Credential")
  valid_591414 = validateParameter(valid_591414, JString, required = false,
                                 default = nil)
  if valid_591414 != nil:
    section.add "X-Amz-Credential", valid_591414
  var valid_591415 = header.getOrDefault("X-Amz-Security-Token")
  valid_591415 = validateParameter(valid_591415, JString, required = false,
                                 default = nil)
  if valid_591415 != nil:
    section.add "X-Amz-Security-Token", valid_591415
  var valid_591416 = header.getOrDefault("X-Amz-Algorithm")
  valid_591416 = validateParameter(valid_591416, JString, required = false,
                                 default = nil)
  if valid_591416 != nil:
    section.add "X-Amz-Algorithm", valid_591416
  var valid_591417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591417 = validateParameter(valid_591417, JString, required = false,
                                 default = nil)
  if valid_591417 != nil:
    section.add "X-Amz-SignedHeaders", valid_591417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591419: Call_DeleteDatabase_591407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_591419.validator(path, query, header, formData, body)
  let scheme = call_591419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591419.url(scheme.get, call_591419.host, call_591419.base,
                         call_591419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591419, url, valid)

proc call*(call_591420: Call_DeleteDatabase_591407; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_591421 = newJObject()
  if body != nil:
    body_591421 = body
  result = call_591420.call(nil, nil, nil, nil, body_591421)

var deleteDatabase* = Call_DeleteDatabase_591407(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_591408, base: "/", url: url_DeleteDatabase_591409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_591422 = ref object of OpenApiRestCall_590364
proc url_DeleteDevEndpoint_591424(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDevEndpoint_591423(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes a specified development endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591425 = header.getOrDefault("X-Amz-Target")
  valid_591425 = validateParameter(valid_591425, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_591425 != nil:
    section.add "X-Amz-Target", valid_591425
  var valid_591426 = header.getOrDefault("X-Amz-Signature")
  valid_591426 = validateParameter(valid_591426, JString, required = false,
                                 default = nil)
  if valid_591426 != nil:
    section.add "X-Amz-Signature", valid_591426
  var valid_591427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591427 = validateParameter(valid_591427, JString, required = false,
                                 default = nil)
  if valid_591427 != nil:
    section.add "X-Amz-Content-Sha256", valid_591427
  var valid_591428 = header.getOrDefault("X-Amz-Date")
  valid_591428 = validateParameter(valid_591428, JString, required = false,
                                 default = nil)
  if valid_591428 != nil:
    section.add "X-Amz-Date", valid_591428
  var valid_591429 = header.getOrDefault("X-Amz-Credential")
  valid_591429 = validateParameter(valid_591429, JString, required = false,
                                 default = nil)
  if valid_591429 != nil:
    section.add "X-Amz-Credential", valid_591429
  var valid_591430 = header.getOrDefault("X-Amz-Security-Token")
  valid_591430 = validateParameter(valid_591430, JString, required = false,
                                 default = nil)
  if valid_591430 != nil:
    section.add "X-Amz-Security-Token", valid_591430
  var valid_591431 = header.getOrDefault("X-Amz-Algorithm")
  valid_591431 = validateParameter(valid_591431, JString, required = false,
                                 default = nil)
  if valid_591431 != nil:
    section.add "X-Amz-Algorithm", valid_591431
  var valid_591432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591432 = validateParameter(valid_591432, JString, required = false,
                                 default = nil)
  if valid_591432 != nil:
    section.add "X-Amz-SignedHeaders", valid_591432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591434: Call_DeleteDevEndpoint_591422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_591434.validator(path, query, header, formData, body)
  let scheme = call_591434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591434.url(scheme.get, call_591434.host, call_591434.base,
                         call_591434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591434, url, valid)

proc call*(call_591435: Call_DeleteDevEndpoint_591422; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_591436 = newJObject()
  if body != nil:
    body_591436 = body
  result = call_591435.call(nil, nil, nil, nil, body_591436)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_591422(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_591423, base: "/",
    url: url_DeleteDevEndpoint_591424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_591437 = ref object of OpenApiRestCall_590364
proc url_DeleteJob_591439(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteJob_591438(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591440 = header.getOrDefault("X-Amz-Target")
  valid_591440 = validateParameter(valid_591440, JString, required = true,
                                 default = newJString("AWSGlue.DeleteJob"))
  if valid_591440 != nil:
    section.add "X-Amz-Target", valid_591440
  var valid_591441 = header.getOrDefault("X-Amz-Signature")
  valid_591441 = validateParameter(valid_591441, JString, required = false,
                                 default = nil)
  if valid_591441 != nil:
    section.add "X-Amz-Signature", valid_591441
  var valid_591442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591442 = validateParameter(valid_591442, JString, required = false,
                                 default = nil)
  if valid_591442 != nil:
    section.add "X-Amz-Content-Sha256", valid_591442
  var valid_591443 = header.getOrDefault("X-Amz-Date")
  valid_591443 = validateParameter(valid_591443, JString, required = false,
                                 default = nil)
  if valid_591443 != nil:
    section.add "X-Amz-Date", valid_591443
  var valid_591444 = header.getOrDefault("X-Amz-Credential")
  valid_591444 = validateParameter(valid_591444, JString, required = false,
                                 default = nil)
  if valid_591444 != nil:
    section.add "X-Amz-Credential", valid_591444
  var valid_591445 = header.getOrDefault("X-Amz-Security-Token")
  valid_591445 = validateParameter(valid_591445, JString, required = false,
                                 default = nil)
  if valid_591445 != nil:
    section.add "X-Amz-Security-Token", valid_591445
  var valid_591446 = header.getOrDefault("X-Amz-Algorithm")
  valid_591446 = validateParameter(valid_591446, JString, required = false,
                                 default = nil)
  if valid_591446 != nil:
    section.add "X-Amz-Algorithm", valid_591446
  var valid_591447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591447 = validateParameter(valid_591447, JString, required = false,
                                 default = nil)
  if valid_591447 != nil:
    section.add "X-Amz-SignedHeaders", valid_591447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591449: Call_DeleteJob_591437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_591449.validator(path, query, header, formData, body)
  let scheme = call_591449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591449.url(scheme.get, call_591449.host, call_591449.base,
                         call_591449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591449, url, valid)

proc call*(call_591450: Call_DeleteJob_591437; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_591451 = newJObject()
  if body != nil:
    body_591451 = body
  result = call_591450.call(nil, nil, nil, nil, body_591451)

var deleteJob* = Call_DeleteJob_591437(name: "deleteJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                    validator: validate_DeleteJob_591438,
                                    base: "/", url: url_DeleteJob_591439,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_591452 = ref object of OpenApiRestCall_590364
proc url_DeleteMLTransform_591454(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMLTransform_591453(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591455 = header.getOrDefault("X-Amz-Target")
  valid_591455 = validateParameter(valid_591455, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_591455 != nil:
    section.add "X-Amz-Target", valid_591455
  var valid_591456 = header.getOrDefault("X-Amz-Signature")
  valid_591456 = validateParameter(valid_591456, JString, required = false,
                                 default = nil)
  if valid_591456 != nil:
    section.add "X-Amz-Signature", valid_591456
  var valid_591457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591457 = validateParameter(valid_591457, JString, required = false,
                                 default = nil)
  if valid_591457 != nil:
    section.add "X-Amz-Content-Sha256", valid_591457
  var valid_591458 = header.getOrDefault("X-Amz-Date")
  valid_591458 = validateParameter(valid_591458, JString, required = false,
                                 default = nil)
  if valid_591458 != nil:
    section.add "X-Amz-Date", valid_591458
  var valid_591459 = header.getOrDefault("X-Amz-Credential")
  valid_591459 = validateParameter(valid_591459, JString, required = false,
                                 default = nil)
  if valid_591459 != nil:
    section.add "X-Amz-Credential", valid_591459
  var valid_591460 = header.getOrDefault("X-Amz-Security-Token")
  valid_591460 = validateParameter(valid_591460, JString, required = false,
                                 default = nil)
  if valid_591460 != nil:
    section.add "X-Amz-Security-Token", valid_591460
  var valid_591461 = header.getOrDefault("X-Amz-Algorithm")
  valid_591461 = validateParameter(valid_591461, JString, required = false,
                                 default = nil)
  if valid_591461 != nil:
    section.add "X-Amz-Algorithm", valid_591461
  var valid_591462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591462 = validateParameter(valid_591462, JString, required = false,
                                 default = nil)
  if valid_591462 != nil:
    section.add "X-Amz-SignedHeaders", valid_591462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591464: Call_DeleteMLTransform_591452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_591464.validator(path, query, header, formData, body)
  let scheme = call_591464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591464.url(scheme.get, call_591464.host, call_591464.base,
                         call_591464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591464, url, valid)

proc call*(call_591465: Call_DeleteMLTransform_591452; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_591466 = newJObject()
  if body != nil:
    body_591466 = body
  result = call_591465.call(nil, nil, nil, nil, body_591466)

var deleteMLTransform* = Call_DeleteMLTransform_591452(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_591453, base: "/",
    url: url_DeleteMLTransform_591454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_591467 = ref object of OpenApiRestCall_590364
proc url_DeletePartition_591469(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePartition_591468(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a specified partition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591470 = header.getOrDefault("X-Amz-Target")
  valid_591470 = validateParameter(valid_591470, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_591470 != nil:
    section.add "X-Amz-Target", valid_591470
  var valid_591471 = header.getOrDefault("X-Amz-Signature")
  valid_591471 = validateParameter(valid_591471, JString, required = false,
                                 default = nil)
  if valid_591471 != nil:
    section.add "X-Amz-Signature", valid_591471
  var valid_591472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591472 = validateParameter(valid_591472, JString, required = false,
                                 default = nil)
  if valid_591472 != nil:
    section.add "X-Amz-Content-Sha256", valid_591472
  var valid_591473 = header.getOrDefault("X-Amz-Date")
  valid_591473 = validateParameter(valid_591473, JString, required = false,
                                 default = nil)
  if valid_591473 != nil:
    section.add "X-Amz-Date", valid_591473
  var valid_591474 = header.getOrDefault("X-Amz-Credential")
  valid_591474 = validateParameter(valid_591474, JString, required = false,
                                 default = nil)
  if valid_591474 != nil:
    section.add "X-Amz-Credential", valid_591474
  var valid_591475 = header.getOrDefault("X-Amz-Security-Token")
  valid_591475 = validateParameter(valid_591475, JString, required = false,
                                 default = nil)
  if valid_591475 != nil:
    section.add "X-Amz-Security-Token", valid_591475
  var valid_591476 = header.getOrDefault("X-Amz-Algorithm")
  valid_591476 = validateParameter(valid_591476, JString, required = false,
                                 default = nil)
  if valid_591476 != nil:
    section.add "X-Amz-Algorithm", valid_591476
  var valid_591477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591477 = validateParameter(valid_591477, JString, required = false,
                                 default = nil)
  if valid_591477 != nil:
    section.add "X-Amz-SignedHeaders", valid_591477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591479: Call_DeletePartition_591467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_591479.validator(path, query, header, formData, body)
  let scheme = call_591479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591479.url(scheme.get, call_591479.host, call_591479.base,
                         call_591479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591479, url, valid)

proc call*(call_591480: Call_DeletePartition_591467; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_591481 = newJObject()
  if body != nil:
    body_591481 = body
  result = call_591480.call(nil, nil, nil, nil, body_591481)

var deletePartition* = Call_DeletePartition_591467(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_591468, base: "/", url: url_DeletePartition_591469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_591482 = ref object of OpenApiRestCall_590364
proc url_DeleteResourcePolicy_591484(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResourcePolicy_591483(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591485 = header.getOrDefault("X-Amz-Target")
  valid_591485 = validateParameter(valid_591485, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_591485 != nil:
    section.add "X-Amz-Target", valid_591485
  var valid_591486 = header.getOrDefault("X-Amz-Signature")
  valid_591486 = validateParameter(valid_591486, JString, required = false,
                                 default = nil)
  if valid_591486 != nil:
    section.add "X-Amz-Signature", valid_591486
  var valid_591487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591487 = validateParameter(valid_591487, JString, required = false,
                                 default = nil)
  if valid_591487 != nil:
    section.add "X-Amz-Content-Sha256", valid_591487
  var valid_591488 = header.getOrDefault("X-Amz-Date")
  valid_591488 = validateParameter(valid_591488, JString, required = false,
                                 default = nil)
  if valid_591488 != nil:
    section.add "X-Amz-Date", valid_591488
  var valid_591489 = header.getOrDefault("X-Amz-Credential")
  valid_591489 = validateParameter(valid_591489, JString, required = false,
                                 default = nil)
  if valid_591489 != nil:
    section.add "X-Amz-Credential", valid_591489
  var valid_591490 = header.getOrDefault("X-Amz-Security-Token")
  valid_591490 = validateParameter(valid_591490, JString, required = false,
                                 default = nil)
  if valid_591490 != nil:
    section.add "X-Amz-Security-Token", valid_591490
  var valid_591491 = header.getOrDefault("X-Amz-Algorithm")
  valid_591491 = validateParameter(valid_591491, JString, required = false,
                                 default = nil)
  if valid_591491 != nil:
    section.add "X-Amz-Algorithm", valid_591491
  var valid_591492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591492 = validateParameter(valid_591492, JString, required = false,
                                 default = nil)
  if valid_591492 != nil:
    section.add "X-Amz-SignedHeaders", valid_591492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591494: Call_DeleteResourcePolicy_591482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_591494.validator(path, query, header, formData, body)
  let scheme = call_591494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591494.url(scheme.get, call_591494.host, call_591494.base,
                         call_591494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591494, url, valid)

proc call*(call_591495: Call_DeleteResourcePolicy_591482; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_591496 = newJObject()
  if body != nil:
    body_591496 = body
  result = call_591495.call(nil, nil, nil, nil, body_591496)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_591482(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_591483, base: "/",
    url: url_DeleteResourcePolicy_591484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_591497 = ref object of OpenApiRestCall_590364
proc url_DeleteSecurityConfiguration_591499(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSecurityConfiguration_591498(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified security configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591500 = header.getOrDefault("X-Amz-Target")
  valid_591500 = validateParameter(valid_591500, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_591500 != nil:
    section.add "X-Amz-Target", valid_591500
  var valid_591501 = header.getOrDefault("X-Amz-Signature")
  valid_591501 = validateParameter(valid_591501, JString, required = false,
                                 default = nil)
  if valid_591501 != nil:
    section.add "X-Amz-Signature", valid_591501
  var valid_591502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591502 = validateParameter(valid_591502, JString, required = false,
                                 default = nil)
  if valid_591502 != nil:
    section.add "X-Amz-Content-Sha256", valid_591502
  var valid_591503 = header.getOrDefault("X-Amz-Date")
  valid_591503 = validateParameter(valid_591503, JString, required = false,
                                 default = nil)
  if valid_591503 != nil:
    section.add "X-Amz-Date", valid_591503
  var valid_591504 = header.getOrDefault("X-Amz-Credential")
  valid_591504 = validateParameter(valid_591504, JString, required = false,
                                 default = nil)
  if valid_591504 != nil:
    section.add "X-Amz-Credential", valid_591504
  var valid_591505 = header.getOrDefault("X-Amz-Security-Token")
  valid_591505 = validateParameter(valid_591505, JString, required = false,
                                 default = nil)
  if valid_591505 != nil:
    section.add "X-Amz-Security-Token", valid_591505
  var valid_591506 = header.getOrDefault("X-Amz-Algorithm")
  valid_591506 = validateParameter(valid_591506, JString, required = false,
                                 default = nil)
  if valid_591506 != nil:
    section.add "X-Amz-Algorithm", valid_591506
  var valid_591507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591507 = validateParameter(valid_591507, JString, required = false,
                                 default = nil)
  if valid_591507 != nil:
    section.add "X-Amz-SignedHeaders", valid_591507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591509: Call_DeleteSecurityConfiguration_591497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_591509.validator(path, query, header, formData, body)
  let scheme = call_591509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591509.url(scheme.get, call_591509.host, call_591509.base,
                         call_591509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591509, url, valid)

proc call*(call_591510: Call_DeleteSecurityConfiguration_591497; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_591511 = newJObject()
  if body != nil:
    body_591511 = body
  result = call_591510.call(nil, nil, nil, nil, body_591511)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_591497(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_591498, base: "/",
    url: url_DeleteSecurityConfiguration_591499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_591512 = ref object of OpenApiRestCall_590364
proc url_DeleteTable_591514(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTable_591513(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591515 = header.getOrDefault("X-Amz-Target")
  valid_591515 = validateParameter(valid_591515, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTable"))
  if valid_591515 != nil:
    section.add "X-Amz-Target", valid_591515
  var valid_591516 = header.getOrDefault("X-Amz-Signature")
  valid_591516 = validateParameter(valid_591516, JString, required = false,
                                 default = nil)
  if valid_591516 != nil:
    section.add "X-Amz-Signature", valid_591516
  var valid_591517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591517 = validateParameter(valid_591517, JString, required = false,
                                 default = nil)
  if valid_591517 != nil:
    section.add "X-Amz-Content-Sha256", valid_591517
  var valid_591518 = header.getOrDefault("X-Amz-Date")
  valid_591518 = validateParameter(valid_591518, JString, required = false,
                                 default = nil)
  if valid_591518 != nil:
    section.add "X-Amz-Date", valid_591518
  var valid_591519 = header.getOrDefault("X-Amz-Credential")
  valid_591519 = validateParameter(valid_591519, JString, required = false,
                                 default = nil)
  if valid_591519 != nil:
    section.add "X-Amz-Credential", valid_591519
  var valid_591520 = header.getOrDefault("X-Amz-Security-Token")
  valid_591520 = validateParameter(valid_591520, JString, required = false,
                                 default = nil)
  if valid_591520 != nil:
    section.add "X-Amz-Security-Token", valid_591520
  var valid_591521 = header.getOrDefault("X-Amz-Algorithm")
  valid_591521 = validateParameter(valid_591521, JString, required = false,
                                 default = nil)
  if valid_591521 != nil:
    section.add "X-Amz-Algorithm", valid_591521
  var valid_591522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591522 = validateParameter(valid_591522, JString, required = false,
                                 default = nil)
  if valid_591522 != nil:
    section.add "X-Amz-SignedHeaders", valid_591522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591524: Call_DeleteTable_591512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_591524.validator(path, query, header, formData, body)
  let scheme = call_591524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591524.url(scheme.get, call_591524.host, call_591524.base,
                         call_591524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591524, url, valid)

proc call*(call_591525: Call_DeleteTable_591512; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_591526 = newJObject()
  if body != nil:
    body_591526 = body
  result = call_591525.call(nil, nil, nil, nil, body_591526)

var deleteTable* = Call_DeleteTable_591512(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteTable",
                                        validator: validate_DeleteTable_591513,
                                        base: "/", url: url_DeleteTable_591514,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_591527 = ref object of OpenApiRestCall_590364
proc url_DeleteTableVersion_591529(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTableVersion_591528(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a specified version of a table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591530 = header.getOrDefault("X-Amz-Target")
  valid_591530 = validateParameter(valid_591530, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_591530 != nil:
    section.add "X-Amz-Target", valid_591530
  var valid_591531 = header.getOrDefault("X-Amz-Signature")
  valid_591531 = validateParameter(valid_591531, JString, required = false,
                                 default = nil)
  if valid_591531 != nil:
    section.add "X-Amz-Signature", valid_591531
  var valid_591532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591532 = validateParameter(valid_591532, JString, required = false,
                                 default = nil)
  if valid_591532 != nil:
    section.add "X-Amz-Content-Sha256", valid_591532
  var valid_591533 = header.getOrDefault("X-Amz-Date")
  valid_591533 = validateParameter(valid_591533, JString, required = false,
                                 default = nil)
  if valid_591533 != nil:
    section.add "X-Amz-Date", valid_591533
  var valid_591534 = header.getOrDefault("X-Amz-Credential")
  valid_591534 = validateParameter(valid_591534, JString, required = false,
                                 default = nil)
  if valid_591534 != nil:
    section.add "X-Amz-Credential", valid_591534
  var valid_591535 = header.getOrDefault("X-Amz-Security-Token")
  valid_591535 = validateParameter(valid_591535, JString, required = false,
                                 default = nil)
  if valid_591535 != nil:
    section.add "X-Amz-Security-Token", valid_591535
  var valid_591536 = header.getOrDefault("X-Amz-Algorithm")
  valid_591536 = validateParameter(valid_591536, JString, required = false,
                                 default = nil)
  if valid_591536 != nil:
    section.add "X-Amz-Algorithm", valid_591536
  var valid_591537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591537 = validateParameter(valid_591537, JString, required = false,
                                 default = nil)
  if valid_591537 != nil:
    section.add "X-Amz-SignedHeaders", valid_591537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591539: Call_DeleteTableVersion_591527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_591539.validator(path, query, header, formData, body)
  let scheme = call_591539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591539.url(scheme.get, call_591539.host, call_591539.base,
                         call_591539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591539, url, valid)

proc call*(call_591540: Call_DeleteTableVersion_591527; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_591541 = newJObject()
  if body != nil:
    body_591541 = body
  result = call_591540.call(nil, nil, nil, nil, body_591541)

var deleteTableVersion* = Call_DeleteTableVersion_591527(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_591528, base: "/",
    url: url_DeleteTableVersion_591529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_591542 = ref object of OpenApiRestCall_590364
proc url_DeleteTrigger_591544(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTrigger_591543(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591545 = header.getOrDefault("X-Amz-Target")
  valid_591545 = validateParameter(valid_591545, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTrigger"))
  if valid_591545 != nil:
    section.add "X-Amz-Target", valid_591545
  var valid_591546 = header.getOrDefault("X-Amz-Signature")
  valid_591546 = validateParameter(valid_591546, JString, required = false,
                                 default = nil)
  if valid_591546 != nil:
    section.add "X-Amz-Signature", valid_591546
  var valid_591547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591547 = validateParameter(valid_591547, JString, required = false,
                                 default = nil)
  if valid_591547 != nil:
    section.add "X-Amz-Content-Sha256", valid_591547
  var valid_591548 = header.getOrDefault("X-Amz-Date")
  valid_591548 = validateParameter(valid_591548, JString, required = false,
                                 default = nil)
  if valid_591548 != nil:
    section.add "X-Amz-Date", valid_591548
  var valid_591549 = header.getOrDefault("X-Amz-Credential")
  valid_591549 = validateParameter(valid_591549, JString, required = false,
                                 default = nil)
  if valid_591549 != nil:
    section.add "X-Amz-Credential", valid_591549
  var valid_591550 = header.getOrDefault("X-Amz-Security-Token")
  valid_591550 = validateParameter(valid_591550, JString, required = false,
                                 default = nil)
  if valid_591550 != nil:
    section.add "X-Amz-Security-Token", valid_591550
  var valid_591551 = header.getOrDefault("X-Amz-Algorithm")
  valid_591551 = validateParameter(valid_591551, JString, required = false,
                                 default = nil)
  if valid_591551 != nil:
    section.add "X-Amz-Algorithm", valid_591551
  var valid_591552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591552 = validateParameter(valid_591552, JString, required = false,
                                 default = nil)
  if valid_591552 != nil:
    section.add "X-Amz-SignedHeaders", valid_591552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591554: Call_DeleteTrigger_591542; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_591554.validator(path, query, header, formData, body)
  let scheme = call_591554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591554.url(scheme.get, call_591554.host, call_591554.base,
                         call_591554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591554, url, valid)

proc call*(call_591555: Call_DeleteTrigger_591542; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_591556 = newJObject()
  if body != nil:
    body_591556 = body
  result = call_591555.call(nil, nil, nil, nil, body_591556)

var deleteTrigger* = Call_DeleteTrigger_591542(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_591543, base: "/", url: url_DeleteTrigger_591544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_591557 = ref object of OpenApiRestCall_590364
proc url_DeleteUserDefinedFunction_591559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUserDefinedFunction_591558(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591560 = header.getOrDefault("X-Amz-Target")
  valid_591560 = validateParameter(valid_591560, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_591560 != nil:
    section.add "X-Amz-Target", valid_591560
  var valid_591561 = header.getOrDefault("X-Amz-Signature")
  valid_591561 = validateParameter(valid_591561, JString, required = false,
                                 default = nil)
  if valid_591561 != nil:
    section.add "X-Amz-Signature", valid_591561
  var valid_591562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591562 = validateParameter(valid_591562, JString, required = false,
                                 default = nil)
  if valid_591562 != nil:
    section.add "X-Amz-Content-Sha256", valid_591562
  var valid_591563 = header.getOrDefault("X-Amz-Date")
  valid_591563 = validateParameter(valid_591563, JString, required = false,
                                 default = nil)
  if valid_591563 != nil:
    section.add "X-Amz-Date", valid_591563
  var valid_591564 = header.getOrDefault("X-Amz-Credential")
  valid_591564 = validateParameter(valid_591564, JString, required = false,
                                 default = nil)
  if valid_591564 != nil:
    section.add "X-Amz-Credential", valid_591564
  var valid_591565 = header.getOrDefault("X-Amz-Security-Token")
  valid_591565 = validateParameter(valid_591565, JString, required = false,
                                 default = nil)
  if valid_591565 != nil:
    section.add "X-Amz-Security-Token", valid_591565
  var valid_591566 = header.getOrDefault("X-Amz-Algorithm")
  valid_591566 = validateParameter(valid_591566, JString, required = false,
                                 default = nil)
  if valid_591566 != nil:
    section.add "X-Amz-Algorithm", valid_591566
  var valid_591567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591567 = validateParameter(valid_591567, JString, required = false,
                                 default = nil)
  if valid_591567 != nil:
    section.add "X-Amz-SignedHeaders", valid_591567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591569: Call_DeleteUserDefinedFunction_591557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_591569.validator(path, query, header, formData, body)
  let scheme = call_591569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591569.url(scheme.get, call_591569.host, call_591569.base,
                         call_591569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591569, url, valid)

proc call*(call_591570: Call_DeleteUserDefinedFunction_591557; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_591571 = newJObject()
  if body != nil:
    body_591571 = body
  result = call_591570.call(nil, nil, nil, nil, body_591571)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_591557(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_591558, base: "/",
    url: url_DeleteUserDefinedFunction_591559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_591572 = ref object of OpenApiRestCall_590364
proc url_DeleteWorkflow_591574(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkflow_591573(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591575 = header.getOrDefault("X-Amz-Target")
  valid_591575 = validateParameter(valid_591575, JString, required = true,
                                 default = newJString("AWSGlue.DeleteWorkflow"))
  if valid_591575 != nil:
    section.add "X-Amz-Target", valid_591575
  var valid_591576 = header.getOrDefault("X-Amz-Signature")
  valid_591576 = validateParameter(valid_591576, JString, required = false,
                                 default = nil)
  if valid_591576 != nil:
    section.add "X-Amz-Signature", valid_591576
  var valid_591577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591577 = validateParameter(valid_591577, JString, required = false,
                                 default = nil)
  if valid_591577 != nil:
    section.add "X-Amz-Content-Sha256", valid_591577
  var valid_591578 = header.getOrDefault("X-Amz-Date")
  valid_591578 = validateParameter(valid_591578, JString, required = false,
                                 default = nil)
  if valid_591578 != nil:
    section.add "X-Amz-Date", valid_591578
  var valid_591579 = header.getOrDefault("X-Amz-Credential")
  valid_591579 = validateParameter(valid_591579, JString, required = false,
                                 default = nil)
  if valid_591579 != nil:
    section.add "X-Amz-Credential", valid_591579
  var valid_591580 = header.getOrDefault("X-Amz-Security-Token")
  valid_591580 = validateParameter(valid_591580, JString, required = false,
                                 default = nil)
  if valid_591580 != nil:
    section.add "X-Amz-Security-Token", valid_591580
  var valid_591581 = header.getOrDefault("X-Amz-Algorithm")
  valid_591581 = validateParameter(valid_591581, JString, required = false,
                                 default = nil)
  if valid_591581 != nil:
    section.add "X-Amz-Algorithm", valid_591581
  var valid_591582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591582 = validateParameter(valid_591582, JString, required = false,
                                 default = nil)
  if valid_591582 != nil:
    section.add "X-Amz-SignedHeaders", valid_591582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591584: Call_DeleteWorkflow_591572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_591584.validator(path, query, header, formData, body)
  let scheme = call_591584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591584.url(scheme.get, call_591584.host, call_591584.base,
                         call_591584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591584, url, valid)

proc call*(call_591585: Call_DeleteWorkflow_591572; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_591586 = newJObject()
  if body != nil:
    body_591586 = body
  result = call_591585.call(nil, nil, nil, nil, body_591586)

var deleteWorkflow* = Call_DeleteWorkflow_591572(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_591573, base: "/", url: url_DeleteWorkflow_591574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_591587 = ref object of OpenApiRestCall_590364
proc url_GetCatalogImportStatus_591589(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCatalogImportStatus_591588(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the status of a migration operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591590 = header.getOrDefault("X-Amz-Target")
  valid_591590 = validateParameter(valid_591590, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_591590 != nil:
    section.add "X-Amz-Target", valid_591590
  var valid_591591 = header.getOrDefault("X-Amz-Signature")
  valid_591591 = validateParameter(valid_591591, JString, required = false,
                                 default = nil)
  if valid_591591 != nil:
    section.add "X-Amz-Signature", valid_591591
  var valid_591592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591592 = validateParameter(valid_591592, JString, required = false,
                                 default = nil)
  if valid_591592 != nil:
    section.add "X-Amz-Content-Sha256", valid_591592
  var valid_591593 = header.getOrDefault("X-Amz-Date")
  valid_591593 = validateParameter(valid_591593, JString, required = false,
                                 default = nil)
  if valid_591593 != nil:
    section.add "X-Amz-Date", valid_591593
  var valid_591594 = header.getOrDefault("X-Amz-Credential")
  valid_591594 = validateParameter(valid_591594, JString, required = false,
                                 default = nil)
  if valid_591594 != nil:
    section.add "X-Amz-Credential", valid_591594
  var valid_591595 = header.getOrDefault("X-Amz-Security-Token")
  valid_591595 = validateParameter(valid_591595, JString, required = false,
                                 default = nil)
  if valid_591595 != nil:
    section.add "X-Amz-Security-Token", valid_591595
  var valid_591596 = header.getOrDefault("X-Amz-Algorithm")
  valid_591596 = validateParameter(valid_591596, JString, required = false,
                                 default = nil)
  if valid_591596 != nil:
    section.add "X-Amz-Algorithm", valid_591596
  var valid_591597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591597 = validateParameter(valid_591597, JString, required = false,
                                 default = nil)
  if valid_591597 != nil:
    section.add "X-Amz-SignedHeaders", valid_591597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591599: Call_GetCatalogImportStatus_591587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_591599.validator(path, query, header, formData, body)
  let scheme = call_591599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591599.url(scheme.get, call_591599.host, call_591599.base,
                         call_591599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591599, url, valid)

proc call*(call_591600: Call_GetCatalogImportStatus_591587; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_591601 = newJObject()
  if body != nil:
    body_591601 = body
  result = call_591600.call(nil, nil, nil, nil, body_591601)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_591587(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_591588, base: "/",
    url: url_GetCatalogImportStatus_591589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_591602 = ref object of OpenApiRestCall_590364
proc url_GetClassifier_591604(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClassifier_591603(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a classifier by name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591605 = header.getOrDefault("X-Amz-Target")
  valid_591605 = validateParameter(valid_591605, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifier"))
  if valid_591605 != nil:
    section.add "X-Amz-Target", valid_591605
  var valid_591606 = header.getOrDefault("X-Amz-Signature")
  valid_591606 = validateParameter(valid_591606, JString, required = false,
                                 default = nil)
  if valid_591606 != nil:
    section.add "X-Amz-Signature", valid_591606
  var valid_591607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591607 = validateParameter(valid_591607, JString, required = false,
                                 default = nil)
  if valid_591607 != nil:
    section.add "X-Amz-Content-Sha256", valid_591607
  var valid_591608 = header.getOrDefault("X-Amz-Date")
  valid_591608 = validateParameter(valid_591608, JString, required = false,
                                 default = nil)
  if valid_591608 != nil:
    section.add "X-Amz-Date", valid_591608
  var valid_591609 = header.getOrDefault("X-Amz-Credential")
  valid_591609 = validateParameter(valid_591609, JString, required = false,
                                 default = nil)
  if valid_591609 != nil:
    section.add "X-Amz-Credential", valid_591609
  var valid_591610 = header.getOrDefault("X-Amz-Security-Token")
  valid_591610 = validateParameter(valid_591610, JString, required = false,
                                 default = nil)
  if valid_591610 != nil:
    section.add "X-Amz-Security-Token", valid_591610
  var valid_591611 = header.getOrDefault("X-Amz-Algorithm")
  valid_591611 = validateParameter(valid_591611, JString, required = false,
                                 default = nil)
  if valid_591611 != nil:
    section.add "X-Amz-Algorithm", valid_591611
  var valid_591612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591612 = validateParameter(valid_591612, JString, required = false,
                                 default = nil)
  if valid_591612 != nil:
    section.add "X-Amz-SignedHeaders", valid_591612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591614: Call_GetClassifier_591602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_591614.validator(path, query, header, formData, body)
  let scheme = call_591614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591614.url(scheme.get, call_591614.host, call_591614.base,
                         call_591614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591614, url, valid)

proc call*(call_591615: Call_GetClassifier_591602; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_591616 = newJObject()
  if body != nil:
    body_591616 = body
  result = call_591615.call(nil, nil, nil, nil, body_591616)

var getClassifier* = Call_GetClassifier_591602(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_591603, base: "/", url: url_GetClassifier_591604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_591617 = ref object of OpenApiRestCall_590364
proc url_GetClassifiers_591619(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClassifiers_591618(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591620 = query.getOrDefault("MaxResults")
  valid_591620 = validateParameter(valid_591620, JString, required = false,
                                 default = nil)
  if valid_591620 != nil:
    section.add "MaxResults", valid_591620
  var valid_591621 = query.getOrDefault("NextToken")
  valid_591621 = validateParameter(valid_591621, JString, required = false,
                                 default = nil)
  if valid_591621 != nil:
    section.add "NextToken", valid_591621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591622 = header.getOrDefault("X-Amz-Target")
  valid_591622 = validateParameter(valid_591622, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifiers"))
  if valid_591622 != nil:
    section.add "X-Amz-Target", valid_591622
  var valid_591623 = header.getOrDefault("X-Amz-Signature")
  valid_591623 = validateParameter(valid_591623, JString, required = false,
                                 default = nil)
  if valid_591623 != nil:
    section.add "X-Amz-Signature", valid_591623
  var valid_591624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591624 = validateParameter(valid_591624, JString, required = false,
                                 default = nil)
  if valid_591624 != nil:
    section.add "X-Amz-Content-Sha256", valid_591624
  var valid_591625 = header.getOrDefault("X-Amz-Date")
  valid_591625 = validateParameter(valid_591625, JString, required = false,
                                 default = nil)
  if valid_591625 != nil:
    section.add "X-Amz-Date", valid_591625
  var valid_591626 = header.getOrDefault("X-Amz-Credential")
  valid_591626 = validateParameter(valid_591626, JString, required = false,
                                 default = nil)
  if valid_591626 != nil:
    section.add "X-Amz-Credential", valid_591626
  var valid_591627 = header.getOrDefault("X-Amz-Security-Token")
  valid_591627 = validateParameter(valid_591627, JString, required = false,
                                 default = nil)
  if valid_591627 != nil:
    section.add "X-Amz-Security-Token", valid_591627
  var valid_591628 = header.getOrDefault("X-Amz-Algorithm")
  valid_591628 = validateParameter(valid_591628, JString, required = false,
                                 default = nil)
  if valid_591628 != nil:
    section.add "X-Amz-Algorithm", valid_591628
  var valid_591629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591629 = validateParameter(valid_591629, JString, required = false,
                                 default = nil)
  if valid_591629 != nil:
    section.add "X-Amz-SignedHeaders", valid_591629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591631: Call_GetClassifiers_591617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_591631.validator(path, query, header, formData, body)
  let scheme = call_591631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591631.url(scheme.get, call_591631.host, call_591631.base,
                         call_591631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591631, url, valid)

proc call*(call_591632: Call_GetClassifiers_591617; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591633 = newJObject()
  var body_591634 = newJObject()
  add(query_591633, "MaxResults", newJString(MaxResults))
  add(query_591633, "NextToken", newJString(NextToken))
  if body != nil:
    body_591634 = body
  result = call_591632.call(nil, query_591633, nil, nil, body_591634)

var getClassifiers* = Call_GetClassifiers_591617(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_591618, base: "/", url: url_GetClassifiers_591619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_591636 = ref object of OpenApiRestCall_590364
proc url_GetConnection_591638(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnection_591637(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591639 = header.getOrDefault("X-Amz-Target")
  valid_591639 = validateParameter(valid_591639, JString, required = true,
                                 default = newJString("AWSGlue.GetConnection"))
  if valid_591639 != nil:
    section.add "X-Amz-Target", valid_591639
  var valid_591640 = header.getOrDefault("X-Amz-Signature")
  valid_591640 = validateParameter(valid_591640, JString, required = false,
                                 default = nil)
  if valid_591640 != nil:
    section.add "X-Amz-Signature", valid_591640
  var valid_591641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591641 = validateParameter(valid_591641, JString, required = false,
                                 default = nil)
  if valid_591641 != nil:
    section.add "X-Amz-Content-Sha256", valid_591641
  var valid_591642 = header.getOrDefault("X-Amz-Date")
  valid_591642 = validateParameter(valid_591642, JString, required = false,
                                 default = nil)
  if valid_591642 != nil:
    section.add "X-Amz-Date", valid_591642
  var valid_591643 = header.getOrDefault("X-Amz-Credential")
  valid_591643 = validateParameter(valid_591643, JString, required = false,
                                 default = nil)
  if valid_591643 != nil:
    section.add "X-Amz-Credential", valid_591643
  var valid_591644 = header.getOrDefault("X-Amz-Security-Token")
  valid_591644 = validateParameter(valid_591644, JString, required = false,
                                 default = nil)
  if valid_591644 != nil:
    section.add "X-Amz-Security-Token", valid_591644
  var valid_591645 = header.getOrDefault("X-Amz-Algorithm")
  valid_591645 = validateParameter(valid_591645, JString, required = false,
                                 default = nil)
  if valid_591645 != nil:
    section.add "X-Amz-Algorithm", valid_591645
  var valid_591646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591646 = validateParameter(valid_591646, JString, required = false,
                                 default = nil)
  if valid_591646 != nil:
    section.add "X-Amz-SignedHeaders", valid_591646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591648: Call_GetConnection_591636; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_591648.validator(path, query, header, formData, body)
  let scheme = call_591648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591648.url(scheme.get, call_591648.host, call_591648.base,
                         call_591648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591648, url, valid)

proc call*(call_591649: Call_GetConnection_591636; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_591650 = newJObject()
  if body != nil:
    body_591650 = body
  result = call_591649.call(nil, nil, nil, nil, body_591650)

var getConnection* = Call_GetConnection_591636(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_591637, base: "/", url: url_GetConnection_591638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_591651 = ref object of OpenApiRestCall_590364
proc url_GetConnections_591653(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnections_591652(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591654 = query.getOrDefault("MaxResults")
  valid_591654 = validateParameter(valid_591654, JString, required = false,
                                 default = nil)
  if valid_591654 != nil:
    section.add "MaxResults", valid_591654
  var valid_591655 = query.getOrDefault("NextToken")
  valid_591655 = validateParameter(valid_591655, JString, required = false,
                                 default = nil)
  if valid_591655 != nil:
    section.add "NextToken", valid_591655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591656 = header.getOrDefault("X-Amz-Target")
  valid_591656 = validateParameter(valid_591656, JString, required = true,
                                 default = newJString("AWSGlue.GetConnections"))
  if valid_591656 != nil:
    section.add "X-Amz-Target", valid_591656
  var valid_591657 = header.getOrDefault("X-Amz-Signature")
  valid_591657 = validateParameter(valid_591657, JString, required = false,
                                 default = nil)
  if valid_591657 != nil:
    section.add "X-Amz-Signature", valid_591657
  var valid_591658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591658 = validateParameter(valid_591658, JString, required = false,
                                 default = nil)
  if valid_591658 != nil:
    section.add "X-Amz-Content-Sha256", valid_591658
  var valid_591659 = header.getOrDefault("X-Amz-Date")
  valid_591659 = validateParameter(valid_591659, JString, required = false,
                                 default = nil)
  if valid_591659 != nil:
    section.add "X-Amz-Date", valid_591659
  var valid_591660 = header.getOrDefault("X-Amz-Credential")
  valid_591660 = validateParameter(valid_591660, JString, required = false,
                                 default = nil)
  if valid_591660 != nil:
    section.add "X-Amz-Credential", valid_591660
  var valid_591661 = header.getOrDefault("X-Amz-Security-Token")
  valid_591661 = validateParameter(valid_591661, JString, required = false,
                                 default = nil)
  if valid_591661 != nil:
    section.add "X-Amz-Security-Token", valid_591661
  var valid_591662 = header.getOrDefault("X-Amz-Algorithm")
  valid_591662 = validateParameter(valid_591662, JString, required = false,
                                 default = nil)
  if valid_591662 != nil:
    section.add "X-Amz-Algorithm", valid_591662
  var valid_591663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591663 = validateParameter(valid_591663, JString, required = false,
                                 default = nil)
  if valid_591663 != nil:
    section.add "X-Amz-SignedHeaders", valid_591663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591665: Call_GetConnections_591651; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_591665.validator(path, query, header, formData, body)
  let scheme = call_591665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591665.url(scheme.get, call_591665.host, call_591665.base,
                         call_591665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591665, url, valid)

proc call*(call_591666: Call_GetConnections_591651; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591667 = newJObject()
  var body_591668 = newJObject()
  add(query_591667, "MaxResults", newJString(MaxResults))
  add(query_591667, "NextToken", newJString(NextToken))
  if body != nil:
    body_591668 = body
  result = call_591666.call(nil, query_591667, nil, nil, body_591668)

var getConnections* = Call_GetConnections_591651(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_591652, base: "/", url: url_GetConnections_591653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_591669 = ref object of OpenApiRestCall_590364
proc url_GetCrawler_591671(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawler_591670(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for a specified crawler.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591672 = header.getOrDefault("X-Amz-Target")
  valid_591672 = validateParameter(valid_591672, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawler"))
  if valid_591672 != nil:
    section.add "X-Amz-Target", valid_591672
  var valid_591673 = header.getOrDefault("X-Amz-Signature")
  valid_591673 = validateParameter(valid_591673, JString, required = false,
                                 default = nil)
  if valid_591673 != nil:
    section.add "X-Amz-Signature", valid_591673
  var valid_591674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591674 = validateParameter(valid_591674, JString, required = false,
                                 default = nil)
  if valid_591674 != nil:
    section.add "X-Amz-Content-Sha256", valid_591674
  var valid_591675 = header.getOrDefault("X-Amz-Date")
  valid_591675 = validateParameter(valid_591675, JString, required = false,
                                 default = nil)
  if valid_591675 != nil:
    section.add "X-Amz-Date", valid_591675
  var valid_591676 = header.getOrDefault("X-Amz-Credential")
  valid_591676 = validateParameter(valid_591676, JString, required = false,
                                 default = nil)
  if valid_591676 != nil:
    section.add "X-Amz-Credential", valid_591676
  var valid_591677 = header.getOrDefault("X-Amz-Security-Token")
  valid_591677 = validateParameter(valid_591677, JString, required = false,
                                 default = nil)
  if valid_591677 != nil:
    section.add "X-Amz-Security-Token", valid_591677
  var valid_591678 = header.getOrDefault("X-Amz-Algorithm")
  valid_591678 = validateParameter(valid_591678, JString, required = false,
                                 default = nil)
  if valid_591678 != nil:
    section.add "X-Amz-Algorithm", valid_591678
  var valid_591679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591679 = validateParameter(valid_591679, JString, required = false,
                                 default = nil)
  if valid_591679 != nil:
    section.add "X-Amz-SignedHeaders", valid_591679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591681: Call_GetCrawler_591669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_591681.validator(path, query, header, formData, body)
  let scheme = call_591681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591681.url(scheme.get, call_591681.host, call_591681.base,
                         call_591681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591681, url, valid)

proc call*(call_591682: Call_GetCrawler_591669; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_591683 = newJObject()
  if body != nil:
    body_591683 = body
  result = call_591682.call(nil, nil, nil, nil, body_591683)

var getCrawler* = Call_GetCrawler_591669(name: "getCrawler",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                      validator: validate_GetCrawler_591670,
                                      base: "/", url: url_GetCrawler_591671,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_591684 = ref object of OpenApiRestCall_590364
proc url_GetCrawlerMetrics_591686(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawlerMetrics_591685(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves metrics about specified crawlers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591687 = query.getOrDefault("MaxResults")
  valid_591687 = validateParameter(valid_591687, JString, required = false,
                                 default = nil)
  if valid_591687 != nil:
    section.add "MaxResults", valid_591687
  var valid_591688 = query.getOrDefault("NextToken")
  valid_591688 = validateParameter(valid_591688, JString, required = false,
                                 default = nil)
  if valid_591688 != nil:
    section.add "NextToken", valid_591688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591689 = header.getOrDefault("X-Amz-Target")
  valid_591689 = validateParameter(valid_591689, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_591689 != nil:
    section.add "X-Amz-Target", valid_591689
  var valid_591690 = header.getOrDefault("X-Amz-Signature")
  valid_591690 = validateParameter(valid_591690, JString, required = false,
                                 default = nil)
  if valid_591690 != nil:
    section.add "X-Amz-Signature", valid_591690
  var valid_591691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591691 = validateParameter(valid_591691, JString, required = false,
                                 default = nil)
  if valid_591691 != nil:
    section.add "X-Amz-Content-Sha256", valid_591691
  var valid_591692 = header.getOrDefault("X-Amz-Date")
  valid_591692 = validateParameter(valid_591692, JString, required = false,
                                 default = nil)
  if valid_591692 != nil:
    section.add "X-Amz-Date", valid_591692
  var valid_591693 = header.getOrDefault("X-Amz-Credential")
  valid_591693 = validateParameter(valid_591693, JString, required = false,
                                 default = nil)
  if valid_591693 != nil:
    section.add "X-Amz-Credential", valid_591693
  var valid_591694 = header.getOrDefault("X-Amz-Security-Token")
  valid_591694 = validateParameter(valid_591694, JString, required = false,
                                 default = nil)
  if valid_591694 != nil:
    section.add "X-Amz-Security-Token", valid_591694
  var valid_591695 = header.getOrDefault("X-Amz-Algorithm")
  valid_591695 = validateParameter(valid_591695, JString, required = false,
                                 default = nil)
  if valid_591695 != nil:
    section.add "X-Amz-Algorithm", valid_591695
  var valid_591696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591696 = validateParameter(valid_591696, JString, required = false,
                                 default = nil)
  if valid_591696 != nil:
    section.add "X-Amz-SignedHeaders", valid_591696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591698: Call_GetCrawlerMetrics_591684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_591698.validator(path, query, header, formData, body)
  let scheme = call_591698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591698.url(scheme.get, call_591698.host, call_591698.base,
                         call_591698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591698, url, valid)

proc call*(call_591699: Call_GetCrawlerMetrics_591684; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591700 = newJObject()
  var body_591701 = newJObject()
  add(query_591700, "MaxResults", newJString(MaxResults))
  add(query_591700, "NextToken", newJString(NextToken))
  if body != nil:
    body_591701 = body
  result = call_591699.call(nil, query_591700, nil, nil, body_591701)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_591684(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_591685, base: "/",
    url: url_GetCrawlerMetrics_591686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_591702 = ref object of OpenApiRestCall_590364
proc url_GetCrawlers_591704(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawlers_591703(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591705 = query.getOrDefault("MaxResults")
  valid_591705 = validateParameter(valid_591705, JString, required = false,
                                 default = nil)
  if valid_591705 != nil:
    section.add "MaxResults", valid_591705
  var valid_591706 = query.getOrDefault("NextToken")
  valid_591706 = validateParameter(valid_591706, JString, required = false,
                                 default = nil)
  if valid_591706 != nil:
    section.add "NextToken", valid_591706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591707 = header.getOrDefault("X-Amz-Target")
  valid_591707 = validateParameter(valid_591707, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawlers"))
  if valid_591707 != nil:
    section.add "X-Amz-Target", valid_591707
  var valid_591708 = header.getOrDefault("X-Amz-Signature")
  valid_591708 = validateParameter(valid_591708, JString, required = false,
                                 default = nil)
  if valid_591708 != nil:
    section.add "X-Amz-Signature", valid_591708
  var valid_591709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591709 = validateParameter(valid_591709, JString, required = false,
                                 default = nil)
  if valid_591709 != nil:
    section.add "X-Amz-Content-Sha256", valid_591709
  var valid_591710 = header.getOrDefault("X-Amz-Date")
  valid_591710 = validateParameter(valid_591710, JString, required = false,
                                 default = nil)
  if valid_591710 != nil:
    section.add "X-Amz-Date", valid_591710
  var valid_591711 = header.getOrDefault("X-Amz-Credential")
  valid_591711 = validateParameter(valid_591711, JString, required = false,
                                 default = nil)
  if valid_591711 != nil:
    section.add "X-Amz-Credential", valid_591711
  var valid_591712 = header.getOrDefault("X-Amz-Security-Token")
  valid_591712 = validateParameter(valid_591712, JString, required = false,
                                 default = nil)
  if valid_591712 != nil:
    section.add "X-Amz-Security-Token", valid_591712
  var valid_591713 = header.getOrDefault("X-Amz-Algorithm")
  valid_591713 = validateParameter(valid_591713, JString, required = false,
                                 default = nil)
  if valid_591713 != nil:
    section.add "X-Amz-Algorithm", valid_591713
  var valid_591714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591714 = validateParameter(valid_591714, JString, required = false,
                                 default = nil)
  if valid_591714 != nil:
    section.add "X-Amz-SignedHeaders", valid_591714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591716: Call_GetCrawlers_591702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_591716.validator(path, query, header, formData, body)
  let scheme = call_591716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591716.url(scheme.get, call_591716.host, call_591716.base,
                         call_591716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591716, url, valid)

proc call*(call_591717: Call_GetCrawlers_591702; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591718 = newJObject()
  var body_591719 = newJObject()
  add(query_591718, "MaxResults", newJString(MaxResults))
  add(query_591718, "NextToken", newJString(NextToken))
  if body != nil:
    body_591719 = body
  result = call_591717.call(nil, query_591718, nil, nil, body_591719)

var getCrawlers* = Call_GetCrawlers_591702(name: "getCrawlers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
                                        validator: validate_GetCrawlers_591703,
                                        base: "/", url: url_GetCrawlers_591704,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_591720 = ref object of OpenApiRestCall_590364
proc url_GetDataCatalogEncryptionSettings_591722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataCatalogEncryptionSettings_591721(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591723 = header.getOrDefault("X-Amz-Target")
  valid_591723 = validateParameter(valid_591723, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_591723 != nil:
    section.add "X-Amz-Target", valid_591723
  var valid_591724 = header.getOrDefault("X-Amz-Signature")
  valid_591724 = validateParameter(valid_591724, JString, required = false,
                                 default = nil)
  if valid_591724 != nil:
    section.add "X-Amz-Signature", valid_591724
  var valid_591725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591725 = validateParameter(valid_591725, JString, required = false,
                                 default = nil)
  if valid_591725 != nil:
    section.add "X-Amz-Content-Sha256", valid_591725
  var valid_591726 = header.getOrDefault("X-Amz-Date")
  valid_591726 = validateParameter(valid_591726, JString, required = false,
                                 default = nil)
  if valid_591726 != nil:
    section.add "X-Amz-Date", valid_591726
  var valid_591727 = header.getOrDefault("X-Amz-Credential")
  valid_591727 = validateParameter(valid_591727, JString, required = false,
                                 default = nil)
  if valid_591727 != nil:
    section.add "X-Amz-Credential", valid_591727
  var valid_591728 = header.getOrDefault("X-Amz-Security-Token")
  valid_591728 = validateParameter(valid_591728, JString, required = false,
                                 default = nil)
  if valid_591728 != nil:
    section.add "X-Amz-Security-Token", valid_591728
  var valid_591729 = header.getOrDefault("X-Amz-Algorithm")
  valid_591729 = validateParameter(valid_591729, JString, required = false,
                                 default = nil)
  if valid_591729 != nil:
    section.add "X-Amz-Algorithm", valid_591729
  var valid_591730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591730 = validateParameter(valid_591730, JString, required = false,
                                 default = nil)
  if valid_591730 != nil:
    section.add "X-Amz-SignedHeaders", valid_591730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591732: Call_GetDataCatalogEncryptionSettings_591720;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_591732.validator(path, query, header, formData, body)
  let scheme = call_591732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591732.url(scheme.get, call_591732.host, call_591732.base,
                         call_591732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591732, url, valid)

proc call*(call_591733: Call_GetDataCatalogEncryptionSettings_591720;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_591734 = newJObject()
  if body != nil:
    body_591734 = body
  result = call_591733.call(nil, nil, nil, nil, body_591734)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_591720(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_591721, base: "/",
    url: url_GetDataCatalogEncryptionSettings_591722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_591735 = ref object of OpenApiRestCall_590364
proc url_GetDatabase_591737(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDatabase_591736(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a specified database.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591738 = header.getOrDefault("X-Amz-Target")
  valid_591738 = validateParameter(valid_591738, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabase"))
  if valid_591738 != nil:
    section.add "X-Amz-Target", valid_591738
  var valid_591739 = header.getOrDefault("X-Amz-Signature")
  valid_591739 = validateParameter(valid_591739, JString, required = false,
                                 default = nil)
  if valid_591739 != nil:
    section.add "X-Amz-Signature", valid_591739
  var valid_591740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591740 = validateParameter(valid_591740, JString, required = false,
                                 default = nil)
  if valid_591740 != nil:
    section.add "X-Amz-Content-Sha256", valid_591740
  var valid_591741 = header.getOrDefault("X-Amz-Date")
  valid_591741 = validateParameter(valid_591741, JString, required = false,
                                 default = nil)
  if valid_591741 != nil:
    section.add "X-Amz-Date", valid_591741
  var valid_591742 = header.getOrDefault("X-Amz-Credential")
  valid_591742 = validateParameter(valid_591742, JString, required = false,
                                 default = nil)
  if valid_591742 != nil:
    section.add "X-Amz-Credential", valid_591742
  var valid_591743 = header.getOrDefault("X-Amz-Security-Token")
  valid_591743 = validateParameter(valid_591743, JString, required = false,
                                 default = nil)
  if valid_591743 != nil:
    section.add "X-Amz-Security-Token", valid_591743
  var valid_591744 = header.getOrDefault("X-Amz-Algorithm")
  valid_591744 = validateParameter(valid_591744, JString, required = false,
                                 default = nil)
  if valid_591744 != nil:
    section.add "X-Amz-Algorithm", valid_591744
  var valid_591745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591745 = validateParameter(valid_591745, JString, required = false,
                                 default = nil)
  if valid_591745 != nil:
    section.add "X-Amz-SignedHeaders", valid_591745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591747: Call_GetDatabase_591735; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_591747.validator(path, query, header, formData, body)
  let scheme = call_591747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591747.url(scheme.get, call_591747.host, call_591747.base,
                         call_591747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591747, url, valid)

proc call*(call_591748: Call_GetDatabase_591735; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_591749 = newJObject()
  if body != nil:
    body_591749 = body
  result = call_591748.call(nil, nil, nil, nil, body_591749)

var getDatabase* = Call_GetDatabase_591735(name: "getDatabase",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetDatabase",
                                        validator: validate_GetDatabase_591736,
                                        base: "/", url: url_GetDatabase_591737,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_591750 = ref object of OpenApiRestCall_590364
proc url_GetDatabases_591752(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDatabases_591751(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591753 = query.getOrDefault("MaxResults")
  valid_591753 = validateParameter(valid_591753, JString, required = false,
                                 default = nil)
  if valid_591753 != nil:
    section.add "MaxResults", valid_591753
  var valid_591754 = query.getOrDefault("NextToken")
  valid_591754 = validateParameter(valid_591754, JString, required = false,
                                 default = nil)
  if valid_591754 != nil:
    section.add "NextToken", valid_591754
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591755 = header.getOrDefault("X-Amz-Target")
  valid_591755 = validateParameter(valid_591755, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabases"))
  if valid_591755 != nil:
    section.add "X-Amz-Target", valid_591755
  var valid_591756 = header.getOrDefault("X-Amz-Signature")
  valid_591756 = validateParameter(valid_591756, JString, required = false,
                                 default = nil)
  if valid_591756 != nil:
    section.add "X-Amz-Signature", valid_591756
  var valid_591757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591757 = validateParameter(valid_591757, JString, required = false,
                                 default = nil)
  if valid_591757 != nil:
    section.add "X-Amz-Content-Sha256", valid_591757
  var valid_591758 = header.getOrDefault("X-Amz-Date")
  valid_591758 = validateParameter(valid_591758, JString, required = false,
                                 default = nil)
  if valid_591758 != nil:
    section.add "X-Amz-Date", valid_591758
  var valid_591759 = header.getOrDefault("X-Amz-Credential")
  valid_591759 = validateParameter(valid_591759, JString, required = false,
                                 default = nil)
  if valid_591759 != nil:
    section.add "X-Amz-Credential", valid_591759
  var valid_591760 = header.getOrDefault("X-Amz-Security-Token")
  valid_591760 = validateParameter(valid_591760, JString, required = false,
                                 default = nil)
  if valid_591760 != nil:
    section.add "X-Amz-Security-Token", valid_591760
  var valid_591761 = header.getOrDefault("X-Amz-Algorithm")
  valid_591761 = validateParameter(valid_591761, JString, required = false,
                                 default = nil)
  if valid_591761 != nil:
    section.add "X-Amz-Algorithm", valid_591761
  var valid_591762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591762 = validateParameter(valid_591762, JString, required = false,
                                 default = nil)
  if valid_591762 != nil:
    section.add "X-Amz-SignedHeaders", valid_591762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591764: Call_GetDatabases_591750; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_591764.validator(path, query, header, formData, body)
  let scheme = call_591764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591764.url(scheme.get, call_591764.host, call_591764.base,
                         call_591764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591764, url, valid)

proc call*(call_591765: Call_GetDatabases_591750; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591766 = newJObject()
  var body_591767 = newJObject()
  add(query_591766, "MaxResults", newJString(MaxResults))
  add(query_591766, "NextToken", newJString(NextToken))
  if body != nil:
    body_591767 = body
  result = call_591765.call(nil, query_591766, nil, nil, body_591767)

var getDatabases* = Call_GetDatabases_591750(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_591751, base: "/", url: url_GetDatabases_591752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_591768 = ref object of OpenApiRestCall_590364
proc url_GetDataflowGraph_591770(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataflowGraph_591769(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591771 = header.getOrDefault("X-Amz-Target")
  valid_591771 = validateParameter(valid_591771, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_591771 != nil:
    section.add "X-Amz-Target", valid_591771
  var valid_591772 = header.getOrDefault("X-Amz-Signature")
  valid_591772 = validateParameter(valid_591772, JString, required = false,
                                 default = nil)
  if valid_591772 != nil:
    section.add "X-Amz-Signature", valid_591772
  var valid_591773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591773 = validateParameter(valid_591773, JString, required = false,
                                 default = nil)
  if valid_591773 != nil:
    section.add "X-Amz-Content-Sha256", valid_591773
  var valid_591774 = header.getOrDefault("X-Amz-Date")
  valid_591774 = validateParameter(valid_591774, JString, required = false,
                                 default = nil)
  if valid_591774 != nil:
    section.add "X-Amz-Date", valid_591774
  var valid_591775 = header.getOrDefault("X-Amz-Credential")
  valid_591775 = validateParameter(valid_591775, JString, required = false,
                                 default = nil)
  if valid_591775 != nil:
    section.add "X-Amz-Credential", valid_591775
  var valid_591776 = header.getOrDefault("X-Amz-Security-Token")
  valid_591776 = validateParameter(valid_591776, JString, required = false,
                                 default = nil)
  if valid_591776 != nil:
    section.add "X-Amz-Security-Token", valid_591776
  var valid_591777 = header.getOrDefault("X-Amz-Algorithm")
  valid_591777 = validateParameter(valid_591777, JString, required = false,
                                 default = nil)
  if valid_591777 != nil:
    section.add "X-Amz-Algorithm", valid_591777
  var valid_591778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591778 = validateParameter(valid_591778, JString, required = false,
                                 default = nil)
  if valid_591778 != nil:
    section.add "X-Amz-SignedHeaders", valid_591778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591780: Call_GetDataflowGraph_591768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_591780.validator(path, query, header, formData, body)
  let scheme = call_591780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591780.url(scheme.get, call_591780.host, call_591780.base,
                         call_591780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591780, url, valid)

proc call*(call_591781: Call_GetDataflowGraph_591768; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_591782 = newJObject()
  if body != nil:
    body_591782 = body
  result = call_591781.call(nil, nil, nil, nil, body_591782)

var getDataflowGraph* = Call_GetDataflowGraph_591768(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_591769, base: "/",
    url: url_GetDataflowGraph_591770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_591783 = ref object of OpenApiRestCall_590364
proc url_GetDevEndpoint_591785(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevEndpoint_591784(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591786 = header.getOrDefault("X-Amz-Target")
  valid_591786 = validateParameter(valid_591786, JString, required = true,
                                 default = newJString("AWSGlue.GetDevEndpoint"))
  if valid_591786 != nil:
    section.add "X-Amz-Target", valid_591786
  var valid_591787 = header.getOrDefault("X-Amz-Signature")
  valid_591787 = validateParameter(valid_591787, JString, required = false,
                                 default = nil)
  if valid_591787 != nil:
    section.add "X-Amz-Signature", valid_591787
  var valid_591788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591788 = validateParameter(valid_591788, JString, required = false,
                                 default = nil)
  if valid_591788 != nil:
    section.add "X-Amz-Content-Sha256", valid_591788
  var valid_591789 = header.getOrDefault("X-Amz-Date")
  valid_591789 = validateParameter(valid_591789, JString, required = false,
                                 default = nil)
  if valid_591789 != nil:
    section.add "X-Amz-Date", valid_591789
  var valid_591790 = header.getOrDefault("X-Amz-Credential")
  valid_591790 = validateParameter(valid_591790, JString, required = false,
                                 default = nil)
  if valid_591790 != nil:
    section.add "X-Amz-Credential", valid_591790
  var valid_591791 = header.getOrDefault("X-Amz-Security-Token")
  valid_591791 = validateParameter(valid_591791, JString, required = false,
                                 default = nil)
  if valid_591791 != nil:
    section.add "X-Amz-Security-Token", valid_591791
  var valid_591792 = header.getOrDefault("X-Amz-Algorithm")
  valid_591792 = validateParameter(valid_591792, JString, required = false,
                                 default = nil)
  if valid_591792 != nil:
    section.add "X-Amz-Algorithm", valid_591792
  var valid_591793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591793 = validateParameter(valid_591793, JString, required = false,
                                 default = nil)
  if valid_591793 != nil:
    section.add "X-Amz-SignedHeaders", valid_591793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591795: Call_GetDevEndpoint_591783; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_591795.validator(path, query, header, formData, body)
  let scheme = call_591795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591795.url(scheme.get, call_591795.host, call_591795.base,
                         call_591795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591795, url, valid)

proc call*(call_591796: Call_GetDevEndpoint_591783; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_591797 = newJObject()
  if body != nil:
    body_591797 = body
  result = call_591796.call(nil, nil, nil, nil, body_591797)

var getDevEndpoint* = Call_GetDevEndpoint_591783(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_591784, base: "/", url: url_GetDevEndpoint_591785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_591798 = ref object of OpenApiRestCall_590364
proc url_GetDevEndpoints_591800(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevEndpoints_591799(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591801 = query.getOrDefault("MaxResults")
  valid_591801 = validateParameter(valid_591801, JString, required = false,
                                 default = nil)
  if valid_591801 != nil:
    section.add "MaxResults", valid_591801
  var valid_591802 = query.getOrDefault("NextToken")
  valid_591802 = validateParameter(valid_591802, JString, required = false,
                                 default = nil)
  if valid_591802 != nil:
    section.add "NextToken", valid_591802
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591803 = header.getOrDefault("X-Amz-Target")
  valid_591803 = validateParameter(valid_591803, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_591803 != nil:
    section.add "X-Amz-Target", valid_591803
  var valid_591804 = header.getOrDefault("X-Amz-Signature")
  valid_591804 = validateParameter(valid_591804, JString, required = false,
                                 default = nil)
  if valid_591804 != nil:
    section.add "X-Amz-Signature", valid_591804
  var valid_591805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591805 = validateParameter(valid_591805, JString, required = false,
                                 default = nil)
  if valid_591805 != nil:
    section.add "X-Amz-Content-Sha256", valid_591805
  var valid_591806 = header.getOrDefault("X-Amz-Date")
  valid_591806 = validateParameter(valid_591806, JString, required = false,
                                 default = nil)
  if valid_591806 != nil:
    section.add "X-Amz-Date", valid_591806
  var valid_591807 = header.getOrDefault("X-Amz-Credential")
  valid_591807 = validateParameter(valid_591807, JString, required = false,
                                 default = nil)
  if valid_591807 != nil:
    section.add "X-Amz-Credential", valid_591807
  var valid_591808 = header.getOrDefault("X-Amz-Security-Token")
  valid_591808 = validateParameter(valid_591808, JString, required = false,
                                 default = nil)
  if valid_591808 != nil:
    section.add "X-Amz-Security-Token", valid_591808
  var valid_591809 = header.getOrDefault("X-Amz-Algorithm")
  valid_591809 = validateParameter(valid_591809, JString, required = false,
                                 default = nil)
  if valid_591809 != nil:
    section.add "X-Amz-Algorithm", valid_591809
  var valid_591810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591810 = validateParameter(valid_591810, JString, required = false,
                                 default = nil)
  if valid_591810 != nil:
    section.add "X-Amz-SignedHeaders", valid_591810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591812: Call_GetDevEndpoints_591798; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_591812.validator(path, query, header, formData, body)
  let scheme = call_591812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591812.url(scheme.get, call_591812.host, call_591812.base,
                         call_591812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591812, url, valid)

proc call*(call_591813: Call_GetDevEndpoints_591798; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591814 = newJObject()
  var body_591815 = newJObject()
  add(query_591814, "MaxResults", newJString(MaxResults))
  add(query_591814, "NextToken", newJString(NextToken))
  if body != nil:
    body_591815 = body
  result = call_591813.call(nil, query_591814, nil, nil, body_591815)

var getDevEndpoints* = Call_GetDevEndpoints_591798(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_591799, base: "/", url: url_GetDevEndpoints_591800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_591816 = ref object of OpenApiRestCall_590364
proc url_GetJob_591818(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJob_591817(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves an existing job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591819 = header.getOrDefault("X-Amz-Target")
  valid_591819 = validateParameter(valid_591819, JString, required = true,
                                 default = newJString("AWSGlue.GetJob"))
  if valid_591819 != nil:
    section.add "X-Amz-Target", valid_591819
  var valid_591820 = header.getOrDefault("X-Amz-Signature")
  valid_591820 = validateParameter(valid_591820, JString, required = false,
                                 default = nil)
  if valid_591820 != nil:
    section.add "X-Amz-Signature", valid_591820
  var valid_591821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591821 = validateParameter(valid_591821, JString, required = false,
                                 default = nil)
  if valid_591821 != nil:
    section.add "X-Amz-Content-Sha256", valid_591821
  var valid_591822 = header.getOrDefault("X-Amz-Date")
  valid_591822 = validateParameter(valid_591822, JString, required = false,
                                 default = nil)
  if valid_591822 != nil:
    section.add "X-Amz-Date", valid_591822
  var valid_591823 = header.getOrDefault("X-Amz-Credential")
  valid_591823 = validateParameter(valid_591823, JString, required = false,
                                 default = nil)
  if valid_591823 != nil:
    section.add "X-Amz-Credential", valid_591823
  var valid_591824 = header.getOrDefault("X-Amz-Security-Token")
  valid_591824 = validateParameter(valid_591824, JString, required = false,
                                 default = nil)
  if valid_591824 != nil:
    section.add "X-Amz-Security-Token", valid_591824
  var valid_591825 = header.getOrDefault("X-Amz-Algorithm")
  valid_591825 = validateParameter(valid_591825, JString, required = false,
                                 default = nil)
  if valid_591825 != nil:
    section.add "X-Amz-Algorithm", valid_591825
  var valid_591826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591826 = validateParameter(valid_591826, JString, required = false,
                                 default = nil)
  if valid_591826 != nil:
    section.add "X-Amz-SignedHeaders", valid_591826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591828: Call_GetJob_591816; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_591828.validator(path, query, header, formData, body)
  let scheme = call_591828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591828.url(scheme.get, call_591828.host, call_591828.base,
                         call_591828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591828, url, valid)

proc call*(call_591829: Call_GetJob_591816; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_591830 = newJObject()
  if body != nil:
    body_591830 = body
  result = call_591829.call(nil, nil, nil, nil, body_591830)

var getJob* = Call_GetJob_591816(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "glue.amazonaws.com",
                              route: "/#X-Amz-Target=AWSGlue.GetJob",
                              validator: validate_GetJob_591817, base: "/",
                              url: url_GetJob_591818,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_591831 = ref object of OpenApiRestCall_590364
proc url_GetJobBookmark_591833(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobBookmark_591832(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information on a job bookmark entry.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591834 = header.getOrDefault("X-Amz-Target")
  valid_591834 = validateParameter(valid_591834, JString, required = true,
                                 default = newJString("AWSGlue.GetJobBookmark"))
  if valid_591834 != nil:
    section.add "X-Amz-Target", valid_591834
  var valid_591835 = header.getOrDefault("X-Amz-Signature")
  valid_591835 = validateParameter(valid_591835, JString, required = false,
                                 default = nil)
  if valid_591835 != nil:
    section.add "X-Amz-Signature", valid_591835
  var valid_591836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591836 = validateParameter(valid_591836, JString, required = false,
                                 default = nil)
  if valid_591836 != nil:
    section.add "X-Amz-Content-Sha256", valid_591836
  var valid_591837 = header.getOrDefault("X-Amz-Date")
  valid_591837 = validateParameter(valid_591837, JString, required = false,
                                 default = nil)
  if valid_591837 != nil:
    section.add "X-Amz-Date", valid_591837
  var valid_591838 = header.getOrDefault("X-Amz-Credential")
  valid_591838 = validateParameter(valid_591838, JString, required = false,
                                 default = nil)
  if valid_591838 != nil:
    section.add "X-Amz-Credential", valid_591838
  var valid_591839 = header.getOrDefault("X-Amz-Security-Token")
  valid_591839 = validateParameter(valid_591839, JString, required = false,
                                 default = nil)
  if valid_591839 != nil:
    section.add "X-Amz-Security-Token", valid_591839
  var valid_591840 = header.getOrDefault("X-Amz-Algorithm")
  valid_591840 = validateParameter(valid_591840, JString, required = false,
                                 default = nil)
  if valid_591840 != nil:
    section.add "X-Amz-Algorithm", valid_591840
  var valid_591841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591841 = validateParameter(valid_591841, JString, required = false,
                                 default = nil)
  if valid_591841 != nil:
    section.add "X-Amz-SignedHeaders", valid_591841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591843: Call_GetJobBookmark_591831; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_591843.validator(path, query, header, formData, body)
  let scheme = call_591843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591843.url(scheme.get, call_591843.host, call_591843.base,
                         call_591843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591843, url, valid)

proc call*(call_591844: Call_GetJobBookmark_591831; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_591845 = newJObject()
  if body != nil:
    body_591845 = body
  result = call_591844.call(nil, nil, nil, nil, body_591845)

var getJobBookmark* = Call_GetJobBookmark_591831(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_591832, base: "/", url: url_GetJobBookmark_591833,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_591846 = ref object of OpenApiRestCall_590364
proc url_GetJobRun_591848(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobRun_591847(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given job run.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591849 = header.getOrDefault("X-Amz-Target")
  valid_591849 = validateParameter(valid_591849, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRun"))
  if valid_591849 != nil:
    section.add "X-Amz-Target", valid_591849
  var valid_591850 = header.getOrDefault("X-Amz-Signature")
  valid_591850 = validateParameter(valid_591850, JString, required = false,
                                 default = nil)
  if valid_591850 != nil:
    section.add "X-Amz-Signature", valid_591850
  var valid_591851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591851 = validateParameter(valid_591851, JString, required = false,
                                 default = nil)
  if valid_591851 != nil:
    section.add "X-Amz-Content-Sha256", valid_591851
  var valid_591852 = header.getOrDefault("X-Amz-Date")
  valid_591852 = validateParameter(valid_591852, JString, required = false,
                                 default = nil)
  if valid_591852 != nil:
    section.add "X-Amz-Date", valid_591852
  var valid_591853 = header.getOrDefault("X-Amz-Credential")
  valid_591853 = validateParameter(valid_591853, JString, required = false,
                                 default = nil)
  if valid_591853 != nil:
    section.add "X-Amz-Credential", valid_591853
  var valid_591854 = header.getOrDefault("X-Amz-Security-Token")
  valid_591854 = validateParameter(valid_591854, JString, required = false,
                                 default = nil)
  if valid_591854 != nil:
    section.add "X-Amz-Security-Token", valid_591854
  var valid_591855 = header.getOrDefault("X-Amz-Algorithm")
  valid_591855 = validateParameter(valid_591855, JString, required = false,
                                 default = nil)
  if valid_591855 != nil:
    section.add "X-Amz-Algorithm", valid_591855
  var valid_591856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591856 = validateParameter(valid_591856, JString, required = false,
                                 default = nil)
  if valid_591856 != nil:
    section.add "X-Amz-SignedHeaders", valid_591856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591858: Call_GetJobRun_591846; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_591858.validator(path, query, header, formData, body)
  let scheme = call_591858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591858.url(scheme.get, call_591858.host, call_591858.base,
                         call_591858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591858, url, valid)

proc call*(call_591859: Call_GetJobRun_591846; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_591860 = newJObject()
  if body != nil:
    body_591860 = body
  result = call_591859.call(nil, nil, nil, nil, body_591860)

var getJobRun* = Call_GetJobRun_591846(name: "getJobRun", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                    validator: validate_GetJobRun_591847,
                                    base: "/", url: url_GetJobRun_591848,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_591861 = ref object of OpenApiRestCall_590364
proc url_GetJobRuns_591863(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobRuns_591862(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591864 = query.getOrDefault("MaxResults")
  valid_591864 = validateParameter(valid_591864, JString, required = false,
                                 default = nil)
  if valid_591864 != nil:
    section.add "MaxResults", valid_591864
  var valid_591865 = query.getOrDefault("NextToken")
  valid_591865 = validateParameter(valid_591865, JString, required = false,
                                 default = nil)
  if valid_591865 != nil:
    section.add "NextToken", valid_591865
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591866 = header.getOrDefault("X-Amz-Target")
  valid_591866 = validateParameter(valid_591866, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRuns"))
  if valid_591866 != nil:
    section.add "X-Amz-Target", valid_591866
  var valid_591867 = header.getOrDefault("X-Amz-Signature")
  valid_591867 = validateParameter(valid_591867, JString, required = false,
                                 default = nil)
  if valid_591867 != nil:
    section.add "X-Amz-Signature", valid_591867
  var valid_591868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591868 = validateParameter(valid_591868, JString, required = false,
                                 default = nil)
  if valid_591868 != nil:
    section.add "X-Amz-Content-Sha256", valid_591868
  var valid_591869 = header.getOrDefault("X-Amz-Date")
  valid_591869 = validateParameter(valid_591869, JString, required = false,
                                 default = nil)
  if valid_591869 != nil:
    section.add "X-Amz-Date", valid_591869
  var valid_591870 = header.getOrDefault("X-Amz-Credential")
  valid_591870 = validateParameter(valid_591870, JString, required = false,
                                 default = nil)
  if valid_591870 != nil:
    section.add "X-Amz-Credential", valid_591870
  var valid_591871 = header.getOrDefault("X-Amz-Security-Token")
  valid_591871 = validateParameter(valid_591871, JString, required = false,
                                 default = nil)
  if valid_591871 != nil:
    section.add "X-Amz-Security-Token", valid_591871
  var valid_591872 = header.getOrDefault("X-Amz-Algorithm")
  valid_591872 = validateParameter(valid_591872, JString, required = false,
                                 default = nil)
  if valid_591872 != nil:
    section.add "X-Amz-Algorithm", valid_591872
  var valid_591873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591873 = validateParameter(valid_591873, JString, required = false,
                                 default = nil)
  if valid_591873 != nil:
    section.add "X-Amz-SignedHeaders", valid_591873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591875: Call_GetJobRuns_591861; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_591875.validator(path, query, header, formData, body)
  let scheme = call_591875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591875.url(scheme.get, call_591875.host, call_591875.base,
                         call_591875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591875, url, valid)

proc call*(call_591876: Call_GetJobRuns_591861; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591877 = newJObject()
  var body_591878 = newJObject()
  add(query_591877, "MaxResults", newJString(MaxResults))
  add(query_591877, "NextToken", newJString(NextToken))
  if body != nil:
    body_591878 = body
  result = call_591876.call(nil, query_591877, nil, nil, body_591878)

var getJobRuns* = Call_GetJobRuns_591861(name: "getJobRuns",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                      validator: validate_GetJobRuns_591862,
                                      base: "/", url: url_GetJobRuns_591863,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_591879 = ref object of OpenApiRestCall_590364
proc url_GetJobs_591881(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobs_591880(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all current job definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591882 = query.getOrDefault("MaxResults")
  valid_591882 = validateParameter(valid_591882, JString, required = false,
                                 default = nil)
  if valid_591882 != nil:
    section.add "MaxResults", valid_591882
  var valid_591883 = query.getOrDefault("NextToken")
  valid_591883 = validateParameter(valid_591883, JString, required = false,
                                 default = nil)
  if valid_591883 != nil:
    section.add "NextToken", valid_591883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591884 = header.getOrDefault("X-Amz-Target")
  valid_591884 = validateParameter(valid_591884, JString, required = true,
                                 default = newJString("AWSGlue.GetJobs"))
  if valid_591884 != nil:
    section.add "X-Amz-Target", valid_591884
  var valid_591885 = header.getOrDefault("X-Amz-Signature")
  valid_591885 = validateParameter(valid_591885, JString, required = false,
                                 default = nil)
  if valid_591885 != nil:
    section.add "X-Amz-Signature", valid_591885
  var valid_591886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591886 = validateParameter(valid_591886, JString, required = false,
                                 default = nil)
  if valid_591886 != nil:
    section.add "X-Amz-Content-Sha256", valid_591886
  var valid_591887 = header.getOrDefault("X-Amz-Date")
  valid_591887 = validateParameter(valid_591887, JString, required = false,
                                 default = nil)
  if valid_591887 != nil:
    section.add "X-Amz-Date", valid_591887
  var valid_591888 = header.getOrDefault("X-Amz-Credential")
  valid_591888 = validateParameter(valid_591888, JString, required = false,
                                 default = nil)
  if valid_591888 != nil:
    section.add "X-Amz-Credential", valid_591888
  var valid_591889 = header.getOrDefault("X-Amz-Security-Token")
  valid_591889 = validateParameter(valid_591889, JString, required = false,
                                 default = nil)
  if valid_591889 != nil:
    section.add "X-Amz-Security-Token", valid_591889
  var valid_591890 = header.getOrDefault("X-Amz-Algorithm")
  valid_591890 = validateParameter(valid_591890, JString, required = false,
                                 default = nil)
  if valid_591890 != nil:
    section.add "X-Amz-Algorithm", valid_591890
  var valid_591891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591891 = validateParameter(valid_591891, JString, required = false,
                                 default = nil)
  if valid_591891 != nil:
    section.add "X-Amz-SignedHeaders", valid_591891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591893: Call_GetJobs_591879; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_591893.validator(path, query, header, formData, body)
  let scheme = call_591893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591893.url(scheme.get, call_591893.host, call_591893.base,
                         call_591893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591893, url, valid)

proc call*(call_591894: Call_GetJobs_591879; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591895 = newJObject()
  var body_591896 = newJObject()
  add(query_591895, "MaxResults", newJString(MaxResults))
  add(query_591895, "NextToken", newJString(NextToken))
  if body != nil:
    body_591896 = body
  result = call_591894.call(nil, query_591895, nil, nil, body_591896)

var getJobs* = Call_GetJobs_591879(name: "getJobs", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                validator: validate_GetJobs_591880, base: "/",
                                url: url_GetJobs_591881,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_591897 = ref object of OpenApiRestCall_590364
proc url_GetMLTaskRun_591899(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTaskRun_591898(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591900 = header.getOrDefault("X-Amz-Target")
  valid_591900 = validateParameter(valid_591900, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_591900 != nil:
    section.add "X-Amz-Target", valid_591900
  var valid_591901 = header.getOrDefault("X-Amz-Signature")
  valid_591901 = validateParameter(valid_591901, JString, required = false,
                                 default = nil)
  if valid_591901 != nil:
    section.add "X-Amz-Signature", valid_591901
  var valid_591902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591902 = validateParameter(valid_591902, JString, required = false,
                                 default = nil)
  if valid_591902 != nil:
    section.add "X-Amz-Content-Sha256", valid_591902
  var valid_591903 = header.getOrDefault("X-Amz-Date")
  valid_591903 = validateParameter(valid_591903, JString, required = false,
                                 default = nil)
  if valid_591903 != nil:
    section.add "X-Amz-Date", valid_591903
  var valid_591904 = header.getOrDefault("X-Amz-Credential")
  valid_591904 = validateParameter(valid_591904, JString, required = false,
                                 default = nil)
  if valid_591904 != nil:
    section.add "X-Amz-Credential", valid_591904
  var valid_591905 = header.getOrDefault("X-Amz-Security-Token")
  valid_591905 = validateParameter(valid_591905, JString, required = false,
                                 default = nil)
  if valid_591905 != nil:
    section.add "X-Amz-Security-Token", valid_591905
  var valid_591906 = header.getOrDefault("X-Amz-Algorithm")
  valid_591906 = validateParameter(valid_591906, JString, required = false,
                                 default = nil)
  if valid_591906 != nil:
    section.add "X-Amz-Algorithm", valid_591906
  var valid_591907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591907 = validateParameter(valid_591907, JString, required = false,
                                 default = nil)
  if valid_591907 != nil:
    section.add "X-Amz-SignedHeaders", valid_591907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591909: Call_GetMLTaskRun_591897; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_591909.validator(path, query, header, formData, body)
  let scheme = call_591909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591909.url(scheme.get, call_591909.host, call_591909.base,
                         call_591909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591909, url, valid)

proc call*(call_591910: Call_GetMLTaskRun_591897; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_591911 = newJObject()
  if body != nil:
    body_591911 = body
  result = call_591910.call(nil, nil, nil, nil, body_591911)

var getMLTaskRun* = Call_GetMLTaskRun_591897(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_591898, base: "/", url: url_GetMLTaskRun_591899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_591912 = ref object of OpenApiRestCall_590364
proc url_GetMLTaskRuns_591914(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTaskRuns_591913(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591915 = query.getOrDefault("MaxResults")
  valid_591915 = validateParameter(valid_591915, JString, required = false,
                                 default = nil)
  if valid_591915 != nil:
    section.add "MaxResults", valid_591915
  var valid_591916 = query.getOrDefault("NextToken")
  valid_591916 = validateParameter(valid_591916, JString, required = false,
                                 default = nil)
  if valid_591916 != nil:
    section.add "NextToken", valid_591916
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591917 = header.getOrDefault("X-Amz-Target")
  valid_591917 = validateParameter(valid_591917, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRuns"))
  if valid_591917 != nil:
    section.add "X-Amz-Target", valid_591917
  var valid_591918 = header.getOrDefault("X-Amz-Signature")
  valid_591918 = validateParameter(valid_591918, JString, required = false,
                                 default = nil)
  if valid_591918 != nil:
    section.add "X-Amz-Signature", valid_591918
  var valid_591919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591919 = validateParameter(valid_591919, JString, required = false,
                                 default = nil)
  if valid_591919 != nil:
    section.add "X-Amz-Content-Sha256", valid_591919
  var valid_591920 = header.getOrDefault("X-Amz-Date")
  valid_591920 = validateParameter(valid_591920, JString, required = false,
                                 default = nil)
  if valid_591920 != nil:
    section.add "X-Amz-Date", valid_591920
  var valid_591921 = header.getOrDefault("X-Amz-Credential")
  valid_591921 = validateParameter(valid_591921, JString, required = false,
                                 default = nil)
  if valid_591921 != nil:
    section.add "X-Amz-Credential", valid_591921
  var valid_591922 = header.getOrDefault("X-Amz-Security-Token")
  valid_591922 = validateParameter(valid_591922, JString, required = false,
                                 default = nil)
  if valid_591922 != nil:
    section.add "X-Amz-Security-Token", valid_591922
  var valid_591923 = header.getOrDefault("X-Amz-Algorithm")
  valid_591923 = validateParameter(valid_591923, JString, required = false,
                                 default = nil)
  if valid_591923 != nil:
    section.add "X-Amz-Algorithm", valid_591923
  var valid_591924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591924 = validateParameter(valid_591924, JString, required = false,
                                 default = nil)
  if valid_591924 != nil:
    section.add "X-Amz-SignedHeaders", valid_591924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591926: Call_GetMLTaskRuns_591912; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_591926.validator(path, query, header, formData, body)
  let scheme = call_591926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591926.url(scheme.get, call_591926.host, call_591926.base,
                         call_591926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591926, url, valid)

proc call*(call_591927: Call_GetMLTaskRuns_591912; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591928 = newJObject()
  var body_591929 = newJObject()
  add(query_591928, "MaxResults", newJString(MaxResults))
  add(query_591928, "NextToken", newJString(NextToken))
  if body != nil:
    body_591929 = body
  result = call_591927.call(nil, query_591928, nil, nil, body_591929)

var getMLTaskRuns* = Call_GetMLTaskRuns_591912(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_591913, base: "/", url: url_GetMLTaskRuns_591914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_591930 = ref object of OpenApiRestCall_590364
proc url_GetMLTransform_591932(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTransform_591931(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591933 = header.getOrDefault("X-Amz-Target")
  valid_591933 = validateParameter(valid_591933, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTransform"))
  if valid_591933 != nil:
    section.add "X-Amz-Target", valid_591933
  var valid_591934 = header.getOrDefault("X-Amz-Signature")
  valid_591934 = validateParameter(valid_591934, JString, required = false,
                                 default = nil)
  if valid_591934 != nil:
    section.add "X-Amz-Signature", valid_591934
  var valid_591935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591935 = validateParameter(valid_591935, JString, required = false,
                                 default = nil)
  if valid_591935 != nil:
    section.add "X-Amz-Content-Sha256", valid_591935
  var valid_591936 = header.getOrDefault("X-Amz-Date")
  valid_591936 = validateParameter(valid_591936, JString, required = false,
                                 default = nil)
  if valid_591936 != nil:
    section.add "X-Amz-Date", valid_591936
  var valid_591937 = header.getOrDefault("X-Amz-Credential")
  valid_591937 = validateParameter(valid_591937, JString, required = false,
                                 default = nil)
  if valid_591937 != nil:
    section.add "X-Amz-Credential", valid_591937
  var valid_591938 = header.getOrDefault("X-Amz-Security-Token")
  valid_591938 = validateParameter(valid_591938, JString, required = false,
                                 default = nil)
  if valid_591938 != nil:
    section.add "X-Amz-Security-Token", valid_591938
  var valid_591939 = header.getOrDefault("X-Amz-Algorithm")
  valid_591939 = validateParameter(valid_591939, JString, required = false,
                                 default = nil)
  if valid_591939 != nil:
    section.add "X-Amz-Algorithm", valid_591939
  var valid_591940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591940 = validateParameter(valid_591940, JString, required = false,
                                 default = nil)
  if valid_591940 != nil:
    section.add "X-Amz-SignedHeaders", valid_591940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591942: Call_GetMLTransform_591930; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_591942.validator(path, query, header, formData, body)
  let scheme = call_591942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591942.url(scheme.get, call_591942.host, call_591942.base,
                         call_591942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591942, url, valid)

proc call*(call_591943: Call_GetMLTransform_591930; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_591944 = newJObject()
  if body != nil:
    body_591944 = body
  result = call_591943.call(nil, nil, nil, nil, body_591944)

var getMLTransform* = Call_GetMLTransform_591930(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_591931, base: "/", url: url_GetMLTransform_591932,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_591945 = ref object of OpenApiRestCall_590364
proc url_GetMLTransforms_591947(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTransforms_591946(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591948 = query.getOrDefault("MaxResults")
  valid_591948 = validateParameter(valid_591948, JString, required = false,
                                 default = nil)
  if valid_591948 != nil:
    section.add "MaxResults", valid_591948
  var valid_591949 = query.getOrDefault("NextToken")
  valid_591949 = validateParameter(valid_591949, JString, required = false,
                                 default = nil)
  if valid_591949 != nil:
    section.add "NextToken", valid_591949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591950 = header.getOrDefault("X-Amz-Target")
  valid_591950 = validateParameter(valid_591950, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_591950 != nil:
    section.add "X-Amz-Target", valid_591950
  var valid_591951 = header.getOrDefault("X-Amz-Signature")
  valid_591951 = validateParameter(valid_591951, JString, required = false,
                                 default = nil)
  if valid_591951 != nil:
    section.add "X-Amz-Signature", valid_591951
  var valid_591952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591952 = validateParameter(valid_591952, JString, required = false,
                                 default = nil)
  if valid_591952 != nil:
    section.add "X-Amz-Content-Sha256", valid_591952
  var valid_591953 = header.getOrDefault("X-Amz-Date")
  valid_591953 = validateParameter(valid_591953, JString, required = false,
                                 default = nil)
  if valid_591953 != nil:
    section.add "X-Amz-Date", valid_591953
  var valid_591954 = header.getOrDefault("X-Amz-Credential")
  valid_591954 = validateParameter(valid_591954, JString, required = false,
                                 default = nil)
  if valid_591954 != nil:
    section.add "X-Amz-Credential", valid_591954
  var valid_591955 = header.getOrDefault("X-Amz-Security-Token")
  valid_591955 = validateParameter(valid_591955, JString, required = false,
                                 default = nil)
  if valid_591955 != nil:
    section.add "X-Amz-Security-Token", valid_591955
  var valid_591956 = header.getOrDefault("X-Amz-Algorithm")
  valid_591956 = validateParameter(valid_591956, JString, required = false,
                                 default = nil)
  if valid_591956 != nil:
    section.add "X-Amz-Algorithm", valid_591956
  var valid_591957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591957 = validateParameter(valid_591957, JString, required = false,
                                 default = nil)
  if valid_591957 != nil:
    section.add "X-Amz-SignedHeaders", valid_591957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591959: Call_GetMLTransforms_591945; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_591959.validator(path, query, header, formData, body)
  let scheme = call_591959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591959.url(scheme.get, call_591959.host, call_591959.base,
                         call_591959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591959, url, valid)

proc call*(call_591960: Call_GetMLTransforms_591945; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591961 = newJObject()
  var body_591962 = newJObject()
  add(query_591961, "MaxResults", newJString(MaxResults))
  add(query_591961, "NextToken", newJString(NextToken))
  if body != nil:
    body_591962 = body
  result = call_591960.call(nil, query_591961, nil, nil, body_591962)

var getMLTransforms* = Call_GetMLTransforms_591945(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_591946, base: "/", url: url_GetMLTransforms_591947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_591963 = ref object of OpenApiRestCall_590364
proc url_GetMapping_591965(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMapping_591964(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates mappings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591966 = header.getOrDefault("X-Amz-Target")
  valid_591966 = validateParameter(valid_591966, JString, required = true,
                                 default = newJString("AWSGlue.GetMapping"))
  if valid_591966 != nil:
    section.add "X-Amz-Target", valid_591966
  var valid_591967 = header.getOrDefault("X-Amz-Signature")
  valid_591967 = validateParameter(valid_591967, JString, required = false,
                                 default = nil)
  if valid_591967 != nil:
    section.add "X-Amz-Signature", valid_591967
  var valid_591968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591968 = validateParameter(valid_591968, JString, required = false,
                                 default = nil)
  if valid_591968 != nil:
    section.add "X-Amz-Content-Sha256", valid_591968
  var valid_591969 = header.getOrDefault("X-Amz-Date")
  valid_591969 = validateParameter(valid_591969, JString, required = false,
                                 default = nil)
  if valid_591969 != nil:
    section.add "X-Amz-Date", valid_591969
  var valid_591970 = header.getOrDefault("X-Amz-Credential")
  valid_591970 = validateParameter(valid_591970, JString, required = false,
                                 default = nil)
  if valid_591970 != nil:
    section.add "X-Amz-Credential", valid_591970
  var valid_591971 = header.getOrDefault("X-Amz-Security-Token")
  valid_591971 = validateParameter(valid_591971, JString, required = false,
                                 default = nil)
  if valid_591971 != nil:
    section.add "X-Amz-Security-Token", valid_591971
  var valid_591972 = header.getOrDefault("X-Amz-Algorithm")
  valid_591972 = validateParameter(valid_591972, JString, required = false,
                                 default = nil)
  if valid_591972 != nil:
    section.add "X-Amz-Algorithm", valid_591972
  var valid_591973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591973 = validateParameter(valid_591973, JString, required = false,
                                 default = nil)
  if valid_591973 != nil:
    section.add "X-Amz-SignedHeaders", valid_591973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591975: Call_GetMapping_591963; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_591975.validator(path, query, header, formData, body)
  let scheme = call_591975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591975.url(scheme.get, call_591975.host, call_591975.base,
                         call_591975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591975, url, valid)

proc call*(call_591976: Call_GetMapping_591963; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_591977 = newJObject()
  if body != nil:
    body_591977 = body
  result = call_591976.call(nil, nil, nil, nil, body_591977)

var getMapping* = Call_GetMapping_591963(name: "getMapping",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                      validator: validate_GetMapping_591964,
                                      base: "/", url: url_GetMapping_591965,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_591978 = ref object of OpenApiRestCall_590364
proc url_GetPartition_591980(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPartition_591979(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specified partition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591981 = header.getOrDefault("X-Amz-Target")
  valid_591981 = validateParameter(valid_591981, JString, required = true,
                                 default = newJString("AWSGlue.GetPartition"))
  if valid_591981 != nil:
    section.add "X-Amz-Target", valid_591981
  var valid_591982 = header.getOrDefault("X-Amz-Signature")
  valid_591982 = validateParameter(valid_591982, JString, required = false,
                                 default = nil)
  if valid_591982 != nil:
    section.add "X-Amz-Signature", valid_591982
  var valid_591983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591983 = validateParameter(valid_591983, JString, required = false,
                                 default = nil)
  if valid_591983 != nil:
    section.add "X-Amz-Content-Sha256", valid_591983
  var valid_591984 = header.getOrDefault("X-Amz-Date")
  valid_591984 = validateParameter(valid_591984, JString, required = false,
                                 default = nil)
  if valid_591984 != nil:
    section.add "X-Amz-Date", valid_591984
  var valid_591985 = header.getOrDefault("X-Amz-Credential")
  valid_591985 = validateParameter(valid_591985, JString, required = false,
                                 default = nil)
  if valid_591985 != nil:
    section.add "X-Amz-Credential", valid_591985
  var valid_591986 = header.getOrDefault("X-Amz-Security-Token")
  valid_591986 = validateParameter(valid_591986, JString, required = false,
                                 default = nil)
  if valid_591986 != nil:
    section.add "X-Amz-Security-Token", valid_591986
  var valid_591987 = header.getOrDefault("X-Amz-Algorithm")
  valid_591987 = validateParameter(valid_591987, JString, required = false,
                                 default = nil)
  if valid_591987 != nil:
    section.add "X-Amz-Algorithm", valid_591987
  var valid_591988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591988 = validateParameter(valid_591988, JString, required = false,
                                 default = nil)
  if valid_591988 != nil:
    section.add "X-Amz-SignedHeaders", valid_591988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591990: Call_GetPartition_591978; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_591990.validator(path, query, header, formData, body)
  let scheme = call_591990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591990.url(scheme.get, call_591990.host, call_591990.base,
                         call_591990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591990, url, valid)

proc call*(call_591991: Call_GetPartition_591978; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_591992 = newJObject()
  if body != nil:
    body_591992 = body
  result = call_591991.call(nil, nil, nil, nil, body_591992)

var getPartition* = Call_GetPartition_591978(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_591979, base: "/", url: url_GetPartition_591980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_591993 = ref object of OpenApiRestCall_590364
proc url_GetPartitions_591995(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPartitions_591994(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the partitions in a table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591996 = query.getOrDefault("MaxResults")
  valid_591996 = validateParameter(valid_591996, JString, required = false,
                                 default = nil)
  if valid_591996 != nil:
    section.add "MaxResults", valid_591996
  var valid_591997 = query.getOrDefault("NextToken")
  valid_591997 = validateParameter(valid_591997, JString, required = false,
                                 default = nil)
  if valid_591997 != nil:
    section.add "NextToken", valid_591997
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591998 = header.getOrDefault("X-Amz-Target")
  valid_591998 = validateParameter(valid_591998, JString, required = true,
                                 default = newJString("AWSGlue.GetPartitions"))
  if valid_591998 != nil:
    section.add "X-Amz-Target", valid_591998
  var valid_591999 = header.getOrDefault("X-Amz-Signature")
  valid_591999 = validateParameter(valid_591999, JString, required = false,
                                 default = nil)
  if valid_591999 != nil:
    section.add "X-Amz-Signature", valid_591999
  var valid_592000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592000 = validateParameter(valid_592000, JString, required = false,
                                 default = nil)
  if valid_592000 != nil:
    section.add "X-Amz-Content-Sha256", valid_592000
  var valid_592001 = header.getOrDefault("X-Amz-Date")
  valid_592001 = validateParameter(valid_592001, JString, required = false,
                                 default = nil)
  if valid_592001 != nil:
    section.add "X-Amz-Date", valid_592001
  var valid_592002 = header.getOrDefault("X-Amz-Credential")
  valid_592002 = validateParameter(valid_592002, JString, required = false,
                                 default = nil)
  if valid_592002 != nil:
    section.add "X-Amz-Credential", valid_592002
  var valid_592003 = header.getOrDefault("X-Amz-Security-Token")
  valid_592003 = validateParameter(valid_592003, JString, required = false,
                                 default = nil)
  if valid_592003 != nil:
    section.add "X-Amz-Security-Token", valid_592003
  var valid_592004 = header.getOrDefault("X-Amz-Algorithm")
  valid_592004 = validateParameter(valid_592004, JString, required = false,
                                 default = nil)
  if valid_592004 != nil:
    section.add "X-Amz-Algorithm", valid_592004
  var valid_592005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592005 = validateParameter(valid_592005, JString, required = false,
                                 default = nil)
  if valid_592005 != nil:
    section.add "X-Amz-SignedHeaders", valid_592005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592007: Call_GetPartitions_591993; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_592007.validator(path, query, header, formData, body)
  let scheme = call_592007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592007.url(scheme.get, call_592007.host, call_592007.base,
                         call_592007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592007, url, valid)

proc call*(call_592008: Call_GetPartitions_591993; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592009 = newJObject()
  var body_592010 = newJObject()
  add(query_592009, "MaxResults", newJString(MaxResults))
  add(query_592009, "NextToken", newJString(NextToken))
  if body != nil:
    body_592010 = body
  result = call_592008.call(nil, query_592009, nil, nil, body_592010)

var getPartitions* = Call_GetPartitions_591993(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_591994, base: "/", url: url_GetPartitions_591995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_592011 = ref object of OpenApiRestCall_590364
proc url_GetPlan_592013(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPlan_592012(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets code to perform a specified mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592014 = header.getOrDefault("X-Amz-Target")
  valid_592014 = validateParameter(valid_592014, JString, required = true,
                                 default = newJString("AWSGlue.GetPlan"))
  if valid_592014 != nil:
    section.add "X-Amz-Target", valid_592014
  var valid_592015 = header.getOrDefault("X-Amz-Signature")
  valid_592015 = validateParameter(valid_592015, JString, required = false,
                                 default = nil)
  if valid_592015 != nil:
    section.add "X-Amz-Signature", valid_592015
  var valid_592016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592016 = validateParameter(valid_592016, JString, required = false,
                                 default = nil)
  if valid_592016 != nil:
    section.add "X-Amz-Content-Sha256", valid_592016
  var valid_592017 = header.getOrDefault("X-Amz-Date")
  valid_592017 = validateParameter(valid_592017, JString, required = false,
                                 default = nil)
  if valid_592017 != nil:
    section.add "X-Amz-Date", valid_592017
  var valid_592018 = header.getOrDefault("X-Amz-Credential")
  valid_592018 = validateParameter(valid_592018, JString, required = false,
                                 default = nil)
  if valid_592018 != nil:
    section.add "X-Amz-Credential", valid_592018
  var valid_592019 = header.getOrDefault("X-Amz-Security-Token")
  valid_592019 = validateParameter(valid_592019, JString, required = false,
                                 default = nil)
  if valid_592019 != nil:
    section.add "X-Amz-Security-Token", valid_592019
  var valid_592020 = header.getOrDefault("X-Amz-Algorithm")
  valid_592020 = validateParameter(valid_592020, JString, required = false,
                                 default = nil)
  if valid_592020 != nil:
    section.add "X-Amz-Algorithm", valid_592020
  var valid_592021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592021 = validateParameter(valid_592021, JString, required = false,
                                 default = nil)
  if valid_592021 != nil:
    section.add "X-Amz-SignedHeaders", valid_592021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592023: Call_GetPlan_592011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_592023.validator(path, query, header, formData, body)
  let scheme = call_592023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592023.url(scheme.get, call_592023.host, call_592023.base,
                         call_592023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592023, url, valid)

proc call*(call_592024: Call_GetPlan_592011; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_592025 = newJObject()
  if body != nil:
    body_592025 = body
  result = call_592024.call(nil, nil, nil, nil, body_592025)

var getPlan* = Call_GetPlan_592011(name: "getPlan", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                validator: validate_GetPlan_592012, base: "/",
                                url: url_GetPlan_592013,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_592026 = ref object of OpenApiRestCall_590364
proc url_GetResourcePolicy_592028(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourcePolicy_592027(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves a specified resource policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592029 = header.getOrDefault("X-Amz-Target")
  valid_592029 = validateParameter(valid_592029, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_592029 != nil:
    section.add "X-Amz-Target", valid_592029
  var valid_592030 = header.getOrDefault("X-Amz-Signature")
  valid_592030 = validateParameter(valid_592030, JString, required = false,
                                 default = nil)
  if valid_592030 != nil:
    section.add "X-Amz-Signature", valid_592030
  var valid_592031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592031 = validateParameter(valid_592031, JString, required = false,
                                 default = nil)
  if valid_592031 != nil:
    section.add "X-Amz-Content-Sha256", valid_592031
  var valid_592032 = header.getOrDefault("X-Amz-Date")
  valid_592032 = validateParameter(valid_592032, JString, required = false,
                                 default = nil)
  if valid_592032 != nil:
    section.add "X-Amz-Date", valid_592032
  var valid_592033 = header.getOrDefault("X-Amz-Credential")
  valid_592033 = validateParameter(valid_592033, JString, required = false,
                                 default = nil)
  if valid_592033 != nil:
    section.add "X-Amz-Credential", valid_592033
  var valid_592034 = header.getOrDefault("X-Amz-Security-Token")
  valid_592034 = validateParameter(valid_592034, JString, required = false,
                                 default = nil)
  if valid_592034 != nil:
    section.add "X-Amz-Security-Token", valid_592034
  var valid_592035 = header.getOrDefault("X-Amz-Algorithm")
  valid_592035 = validateParameter(valid_592035, JString, required = false,
                                 default = nil)
  if valid_592035 != nil:
    section.add "X-Amz-Algorithm", valid_592035
  var valid_592036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592036 = validateParameter(valid_592036, JString, required = false,
                                 default = nil)
  if valid_592036 != nil:
    section.add "X-Amz-SignedHeaders", valid_592036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592038: Call_GetResourcePolicy_592026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_592038.validator(path, query, header, formData, body)
  let scheme = call_592038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592038.url(scheme.get, call_592038.host, call_592038.base,
                         call_592038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592038, url, valid)

proc call*(call_592039: Call_GetResourcePolicy_592026; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_592040 = newJObject()
  if body != nil:
    body_592040 = body
  result = call_592039.call(nil, nil, nil, nil, body_592040)

var getResourcePolicy* = Call_GetResourcePolicy_592026(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_592027, base: "/",
    url: url_GetResourcePolicy_592028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_592041 = ref object of OpenApiRestCall_590364
proc url_GetSecurityConfiguration_592043(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSecurityConfiguration_592042(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified security configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592044 = header.getOrDefault("X-Amz-Target")
  valid_592044 = validateParameter(valid_592044, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_592044 != nil:
    section.add "X-Amz-Target", valid_592044
  var valid_592045 = header.getOrDefault("X-Amz-Signature")
  valid_592045 = validateParameter(valid_592045, JString, required = false,
                                 default = nil)
  if valid_592045 != nil:
    section.add "X-Amz-Signature", valid_592045
  var valid_592046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592046 = validateParameter(valid_592046, JString, required = false,
                                 default = nil)
  if valid_592046 != nil:
    section.add "X-Amz-Content-Sha256", valid_592046
  var valid_592047 = header.getOrDefault("X-Amz-Date")
  valid_592047 = validateParameter(valid_592047, JString, required = false,
                                 default = nil)
  if valid_592047 != nil:
    section.add "X-Amz-Date", valid_592047
  var valid_592048 = header.getOrDefault("X-Amz-Credential")
  valid_592048 = validateParameter(valid_592048, JString, required = false,
                                 default = nil)
  if valid_592048 != nil:
    section.add "X-Amz-Credential", valid_592048
  var valid_592049 = header.getOrDefault("X-Amz-Security-Token")
  valid_592049 = validateParameter(valid_592049, JString, required = false,
                                 default = nil)
  if valid_592049 != nil:
    section.add "X-Amz-Security-Token", valid_592049
  var valid_592050 = header.getOrDefault("X-Amz-Algorithm")
  valid_592050 = validateParameter(valid_592050, JString, required = false,
                                 default = nil)
  if valid_592050 != nil:
    section.add "X-Amz-Algorithm", valid_592050
  var valid_592051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592051 = validateParameter(valid_592051, JString, required = false,
                                 default = nil)
  if valid_592051 != nil:
    section.add "X-Amz-SignedHeaders", valid_592051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592053: Call_GetSecurityConfiguration_592041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_592053.validator(path, query, header, formData, body)
  let scheme = call_592053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592053.url(scheme.get, call_592053.host, call_592053.base,
                         call_592053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592053, url, valid)

proc call*(call_592054: Call_GetSecurityConfiguration_592041; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_592055 = newJObject()
  if body != nil:
    body_592055 = body
  result = call_592054.call(nil, nil, nil, nil, body_592055)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_592041(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_592042, base: "/",
    url: url_GetSecurityConfiguration_592043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_592056 = ref object of OpenApiRestCall_590364
proc url_GetSecurityConfigurations_592058(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSecurityConfigurations_592057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of all security configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592059 = query.getOrDefault("MaxResults")
  valid_592059 = validateParameter(valid_592059, JString, required = false,
                                 default = nil)
  if valid_592059 != nil:
    section.add "MaxResults", valid_592059
  var valid_592060 = query.getOrDefault("NextToken")
  valid_592060 = validateParameter(valid_592060, JString, required = false,
                                 default = nil)
  if valid_592060 != nil:
    section.add "NextToken", valid_592060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592061 = header.getOrDefault("X-Amz-Target")
  valid_592061 = validateParameter(valid_592061, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_592061 != nil:
    section.add "X-Amz-Target", valid_592061
  var valid_592062 = header.getOrDefault("X-Amz-Signature")
  valid_592062 = validateParameter(valid_592062, JString, required = false,
                                 default = nil)
  if valid_592062 != nil:
    section.add "X-Amz-Signature", valid_592062
  var valid_592063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592063 = validateParameter(valid_592063, JString, required = false,
                                 default = nil)
  if valid_592063 != nil:
    section.add "X-Amz-Content-Sha256", valid_592063
  var valid_592064 = header.getOrDefault("X-Amz-Date")
  valid_592064 = validateParameter(valid_592064, JString, required = false,
                                 default = nil)
  if valid_592064 != nil:
    section.add "X-Amz-Date", valid_592064
  var valid_592065 = header.getOrDefault("X-Amz-Credential")
  valid_592065 = validateParameter(valid_592065, JString, required = false,
                                 default = nil)
  if valid_592065 != nil:
    section.add "X-Amz-Credential", valid_592065
  var valid_592066 = header.getOrDefault("X-Amz-Security-Token")
  valid_592066 = validateParameter(valid_592066, JString, required = false,
                                 default = nil)
  if valid_592066 != nil:
    section.add "X-Amz-Security-Token", valid_592066
  var valid_592067 = header.getOrDefault("X-Amz-Algorithm")
  valid_592067 = validateParameter(valid_592067, JString, required = false,
                                 default = nil)
  if valid_592067 != nil:
    section.add "X-Amz-Algorithm", valid_592067
  var valid_592068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592068 = validateParameter(valid_592068, JString, required = false,
                                 default = nil)
  if valid_592068 != nil:
    section.add "X-Amz-SignedHeaders", valid_592068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592070: Call_GetSecurityConfigurations_592056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_592070.validator(path, query, header, formData, body)
  let scheme = call_592070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592070.url(scheme.get, call_592070.host, call_592070.base,
                         call_592070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592070, url, valid)

proc call*(call_592071: Call_GetSecurityConfigurations_592056; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592072 = newJObject()
  var body_592073 = newJObject()
  add(query_592072, "MaxResults", newJString(MaxResults))
  add(query_592072, "NextToken", newJString(NextToken))
  if body != nil:
    body_592073 = body
  result = call_592071.call(nil, query_592072, nil, nil, body_592073)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_592056(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_592057, base: "/",
    url: url_GetSecurityConfigurations_592058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_592074 = ref object of OpenApiRestCall_590364
proc url_GetTable_592076(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTable_592075(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592077 = header.getOrDefault("X-Amz-Target")
  valid_592077 = validateParameter(valid_592077, JString, required = true,
                                 default = newJString("AWSGlue.GetTable"))
  if valid_592077 != nil:
    section.add "X-Amz-Target", valid_592077
  var valid_592078 = header.getOrDefault("X-Amz-Signature")
  valid_592078 = validateParameter(valid_592078, JString, required = false,
                                 default = nil)
  if valid_592078 != nil:
    section.add "X-Amz-Signature", valid_592078
  var valid_592079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592079 = validateParameter(valid_592079, JString, required = false,
                                 default = nil)
  if valid_592079 != nil:
    section.add "X-Amz-Content-Sha256", valid_592079
  var valid_592080 = header.getOrDefault("X-Amz-Date")
  valid_592080 = validateParameter(valid_592080, JString, required = false,
                                 default = nil)
  if valid_592080 != nil:
    section.add "X-Amz-Date", valid_592080
  var valid_592081 = header.getOrDefault("X-Amz-Credential")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "X-Amz-Credential", valid_592081
  var valid_592082 = header.getOrDefault("X-Amz-Security-Token")
  valid_592082 = validateParameter(valid_592082, JString, required = false,
                                 default = nil)
  if valid_592082 != nil:
    section.add "X-Amz-Security-Token", valid_592082
  var valid_592083 = header.getOrDefault("X-Amz-Algorithm")
  valid_592083 = validateParameter(valid_592083, JString, required = false,
                                 default = nil)
  if valid_592083 != nil:
    section.add "X-Amz-Algorithm", valid_592083
  var valid_592084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592084 = validateParameter(valid_592084, JString, required = false,
                                 default = nil)
  if valid_592084 != nil:
    section.add "X-Amz-SignedHeaders", valid_592084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592086: Call_GetTable_592074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_592086.validator(path, query, header, formData, body)
  let scheme = call_592086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592086.url(scheme.get, call_592086.host, call_592086.base,
                         call_592086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592086, url, valid)

proc call*(call_592087: Call_GetTable_592074; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_592088 = newJObject()
  if body != nil:
    body_592088 = body
  result = call_592087.call(nil, nil, nil, nil, body_592088)

var getTable* = Call_GetTable_592074(name: "getTable", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTable",
                                  validator: validate_GetTable_592075, base: "/",
                                  url: url_GetTable_592076,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_592089 = ref object of OpenApiRestCall_590364
proc url_GetTableVersion_592091(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTableVersion_592090(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a specified version of a table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592092 = header.getOrDefault("X-Amz-Target")
  valid_592092 = validateParameter(valid_592092, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_592092 != nil:
    section.add "X-Amz-Target", valid_592092
  var valid_592093 = header.getOrDefault("X-Amz-Signature")
  valid_592093 = validateParameter(valid_592093, JString, required = false,
                                 default = nil)
  if valid_592093 != nil:
    section.add "X-Amz-Signature", valid_592093
  var valid_592094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592094 = validateParameter(valid_592094, JString, required = false,
                                 default = nil)
  if valid_592094 != nil:
    section.add "X-Amz-Content-Sha256", valid_592094
  var valid_592095 = header.getOrDefault("X-Amz-Date")
  valid_592095 = validateParameter(valid_592095, JString, required = false,
                                 default = nil)
  if valid_592095 != nil:
    section.add "X-Amz-Date", valid_592095
  var valid_592096 = header.getOrDefault("X-Amz-Credential")
  valid_592096 = validateParameter(valid_592096, JString, required = false,
                                 default = nil)
  if valid_592096 != nil:
    section.add "X-Amz-Credential", valid_592096
  var valid_592097 = header.getOrDefault("X-Amz-Security-Token")
  valid_592097 = validateParameter(valid_592097, JString, required = false,
                                 default = nil)
  if valid_592097 != nil:
    section.add "X-Amz-Security-Token", valid_592097
  var valid_592098 = header.getOrDefault("X-Amz-Algorithm")
  valid_592098 = validateParameter(valid_592098, JString, required = false,
                                 default = nil)
  if valid_592098 != nil:
    section.add "X-Amz-Algorithm", valid_592098
  var valid_592099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592099 = validateParameter(valid_592099, JString, required = false,
                                 default = nil)
  if valid_592099 != nil:
    section.add "X-Amz-SignedHeaders", valid_592099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592101: Call_GetTableVersion_592089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_592101.validator(path, query, header, formData, body)
  let scheme = call_592101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592101.url(scheme.get, call_592101.host, call_592101.base,
                         call_592101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592101, url, valid)

proc call*(call_592102: Call_GetTableVersion_592089; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_592103 = newJObject()
  if body != nil:
    body_592103 = body
  result = call_592102.call(nil, nil, nil, nil, body_592103)

var getTableVersion* = Call_GetTableVersion_592089(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_592090, base: "/", url: url_GetTableVersion_592091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_592104 = ref object of OpenApiRestCall_590364
proc url_GetTableVersions_592106(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTableVersions_592105(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592107 = query.getOrDefault("MaxResults")
  valid_592107 = validateParameter(valid_592107, JString, required = false,
                                 default = nil)
  if valid_592107 != nil:
    section.add "MaxResults", valid_592107
  var valid_592108 = query.getOrDefault("NextToken")
  valid_592108 = validateParameter(valid_592108, JString, required = false,
                                 default = nil)
  if valid_592108 != nil:
    section.add "NextToken", valid_592108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592109 = header.getOrDefault("X-Amz-Target")
  valid_592109 = validateParameter(valid_592109, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_592109 != nil:
    section.add "X-Amz-Target", valid_592109
  var valid_592110 = header.getOrDefault("X-Amz-Signature")
  valid_592110 = validateParameter(valid_592110, JString, required = false,
                                 default = nil)
  if valid_592110 != nil:
    section.add "X-Amz-Signature", valid_592110
  var valid_592111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592111 = validateParameter(valid_592111, JString, required = false,
                                 default = nil)
  if valid_592111 != nil:
    section.add "X-Amz-Content-Sha256", valid_592111
  var valid_592112 = header.getOrDefault("X-Amz-Date")
  valid_592112 = validateParameter(valid_592112, JString, required = false,
                                 default = nil)
  if valid_592112 != nil:
    section.add "X-Amz-Date", valid_592112
  var valid_592113 = header.getOrDefault("X-Amz-Credential")
  valid_592113 = validateParameter(valid_592113, JString, required = false,
                                 default = nil)
  if valid_592113 != nil:
    section.add "X-Amz-Credential", valid_592113
  var valid_592114 = header.getOrDefault("X-Amz-Security-Token")
  valid_592114 = validateParameter(valid_592114, JString, required = false,
                                 default = nil)
  if valid_592114 != nil:
    section.add "X-Amz-Security-Token", valid_592114
  var valid_592115 = header.getOrDefault("X-Amz-Algorithm")
  valid_592115 = validateParameter(valid_592115, JString, required = false,
                                 default = nil)
  if valid_592115 != nil:
    section.add "X-Amz-Algorithm", valid_592115
  var valid_592116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592116 = validateParameter(valid_592116, JString, required = false,
                                 default = nil)
  if valid_592116 != nil:
    section.add "X-Amz-SignedHeaders", valid_592116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592118: Call_GetTableVersions_592104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_592118.validator(path, query, header, formData, body)
  let scheme = call_592118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592118.url(scheme.get, call_592118.host, call_592118.base,
                         call_592118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592118, url, valid)

proc call*(call_592119: Call_GetTableVersions_592104; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592120 = newJObject()
  var body_592121 = newJObject()
  add(query_592120, "MaxResults", newJString(MaxResults))
  add(query_592120, "NextToken", newJString(NextToken))
  if body != nil:
    body_592121 = body
  result = call_592119.call(nil, query_592120, nil, nil, body_592121)

var getTableVersions* = Call_GetTableVersions_592104(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_592105, base: "/",
    url: url_GetTableVersions_592106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_592122 = ref object of OpenApiRestCall_590364
proc url_GetTables_592124(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTables_592123(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592125 = query.getOrDefault("MaxResults")
  valid_592125 = validateParameter(valid_592125, JString, required = false,
                                 default = nil)
  if valid_592125 != nil:
    section.add "MaxResults", valid_592125
  var valid_592126 = query.getOrDefault("NextToken")
  valid_592126 = validateParameter(valid_592126, JString, required = false,
                                 default = nil)
  if valid_592126 != nil:
    section.add "NextToken", valid_592126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592127 = header.getOrDefault("X-Amz-Target")
  valid_592127 = validateParameter(valid_592127, JString, required = true,
                                 default = newJString("AWSGlue.GetTables"))
  if valid_592127 != nil:
    section.add "X-Amz-Target", valid_592127
  var valid_592128 = header.getOrDefault("X-Amz-Signature")
  valid_592128 = validateParameter(valid_592128, JString, required = false,
                                 default = nil)
  if valid_592128 != nil:
    section.add "X-Amz-Signature", valid_592128
  var valid_592129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592129 = validateParameter(valid_592129, JString, required = false,
                                 default = nil)
  if valid_592129 != nil:
    section.add "X-Amz-Content-Sha256", valid_592129
  var valid_592130 = header.getOrDefault("X-Amz-Date")
  valid_592130 = validateParameter(valid_592130, JString, required = false,
                                 default = nil)
  if valid_592130 != nil:
    section.add "X-Amz-Date", valid_592130
  var valid_592131 = header.getOrDefault("X-Amz-Credential")
  valid_592131 = validateParameter(valid_592131, JString, required = false,
                                 default = nil)
  if valid_592131 != nil:
    section.add "X-Amz-Credential", valid_592131
  var valid_592132 = header.getOrDefault("X-Amz-Security-Token")
  valid_592132 = validateParameter(valid_592132, JString, required = false,
                                 default = nil)
  if valid_592132 != nil:
    section.add "X-Amz-Security-Token", valid_592132
  var valid_592133 = header.getOrDefault("X-Amz-Algorithm")
  valid_592133 = validateParameter(valid_592133, JString, required = false,
                                 default = nil)
  if valid_592133 != nil:
    section.add "X-Amz-Algorithm", valid_592133
  var valid_592134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592134 = validateParameter(valid_592134, JString, required = false,
                                 default = nil)
  if valid_592134 != nil:
    section.add "X-Amz-SignedHeaders", valid_592134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592136: Call_GetTables_592122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_592136.validator(path, query, header, formData, body)
  let scheme = call_592136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592136.url(scheme.get, call_592136.host, call_592136.base,
                         call_592136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592136, url, valid)

proc call*(call_592137: Call_GetTables_592122; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592138 = newJObject()
  var body_592139 = newJObject()
  add(query_592138, "MaxResults", newJString(MaxResults))
  add(query_592138, "NextToken", newJString(NextToken))
  if body != nil:
    body_592139 = body
  result = call_592137.call(nil, query_592138, nil, nil, body_592139)

var getTables* = Call_GetTables_592122(name: "getTables", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTables",
                                    validator: validate_GetTables_592123,
                                    base: "/", url: url_GetTables_592124,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_592140 = ref object of OpenApiRestCall_590364
proc url_GetTags_592142(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTags_592141(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of tags associated with a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592143 = header.getOrDefault("X-Amz-Target")
  valid_592143 = validateParameter(valid_592143, JString, required = true,
                                 default = newJString("AWSGlue.GetTags"))
  if valid_592143 != nil:
    section.add "X-Amz-Target", valid_592143
  var valid_592144 = header.getOrDefault("X-Amz-Signature")
  valid_592144 = validateParameter(valid_592144, JString, required = false,
                                 default = nil)
  if valid_592144 != nil:
    section.add "X-Amz-Signature", valid_592144
  var valid_592145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592145 = validateParameter(valid_592145, JString, required = false,
                                 default = nil)
  if valid_592145 != nil:
    section.add "X-Amz-Content-Sha256", valid_592145
  var valid_592146 = header.getOrDefault("X-Amz-Date")
  valid_592146 = validateParameter(valid_592146, JString, required = false,
                                 default = nil)
  if valid_592146 != nil:
    section.add "X-Amz-Date", valid_592146
  var valid_592147 = header.getOrDefault("X-Amz-Credential")
  valid_592147 = validateParameter(valid_592147, JString, required = false,
                                 default = nil)
  if valid_592147 != nil:
    section.add "X-Amz-Credential", valid_592147
  var valid_592148 = header.getOrDefault("X-Amz-Security-Token")
  valid_592148 = validateParameter(valid_592148, JString, required = false,
                                 default = nil)
  if valid_592148 != nil:
    section.add "X-Amz-Security-Token", valid_592148
  var valid_592149 = header.getOrDefault("X-Amz-Algorithm")
  valid_592149 = validateParameter(valid_592149, JString, required = false,
                                 default = nil)
  if valid_592149 != nil:
    section.add "X-Amz-Algorithm", valid_592149
  var valid_592150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592150 = validateParameter(valid_592150, JString, required = false,
                                 default = nil)
  if valid_592150 != nil:
    section.add "X-Amz-SignedHeaders", valid_592150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592152: Call_GetTags_592140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_592152.validator(path, query, header, formData, body)
  let scheme = call_592152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592152.url(scheme.get, call_592152.host, call_592152.base,
                         call_592152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592152, url, valid)

proc call*(call_592153: Call_GetTags_592140; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_592154 = newJObject()
  if body != nil:
    body_592154 = body
  result = call_592153.call(nil, nil, nil, nil, body_592154)

var getTags* = Call_GetTags_592140(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetTags",
                                validator: validate_GetTags_592141, base: "/",
                                url: url_GetTags_592142,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_592155 = ref object of OpenApiRestCall_590364
proc url_GetTrigger_592157(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTrigger_592156(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a trigger.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592158 = header.getOrDefault("X-Amz-Target")
  valid_592158 = validateParameter(valid_592158, JString, required = true,
                                 default = newJString("AWSGlue.GetTrigger"))
  if valid_592158 != nil:
    section.add "X-Amz-Target", valid_592158
  var valid_592159 = header.getOrDefault("X-Amz-Signature")
  valid_592159 = validateParameter(valid_592159, JString, required = false,
                                 default = nil)
  if valid_592159 != nil:
    section.add "X-Amz-Signature", valid_592159
  var valid_592160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592160 = validateParameter(valid_592160, JString, required = false,
                                 default = nil)
  if valid_592160 != nil:
    section.add "X-Amz-Content-Sha256", valid_592160
  var valid_592161 = header.getOrDefault("X-Amz-Date")
  valid_592161 = validateParameter(valid_592161, JString, required = false,
                                 default = nil)
  if valid_592161 != nil:
    section.add "X-Amz-Date", valid_592161
  var valid_592162 = header.getOrDefault("X-Amz-Credential")
  valid_592162 = validateParameter(valid_592162, JString, required = false,
                                 default = nil)
  if valid_592162 != nil:
    section.add "X-Amz-Credential", valid_592162
  var valid_592163 = header.getOrDefault("X-Amz-Security-Token")
  valid_592163 = validateParameter(valid_592163, JString, required = false,
                                 default = nil)
  if valid_592163 != nil:
    section.add "X-Amz-Security-Token", valid_592163
  var valid_592164 = header.getOrDefault("X-Amz-Algorithm")
  valid_592164 = validateParameter(valid_592164, JString, required = false,
                                 default = nil)
  if valid_592164 != nil:
    section.add "X-Amz-Algorithm", valid_592164
  var valid_592165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592165 = validateParameter(valid_592165, JString, required = false,
                                 default = nil)
  if valid_592165 != nil:
    section.add "X-Amz-SignedHeaders", valid_592165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592167: Call_GetTrigger_592155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_592167.validator(path, query, header, formData, body)
  let scheme = call_592167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592167.url(scheme.get, call_592167.host, call_592167.base,
                         call_592167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592167, url, valid)

proc call*(call_592168: Call_GetTrigger_592155; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_592169 = newJObject()
  if body != nil:
    body_592169 = body
  result = call_592168.call(nil, nil, nil, nil, body_592169)

var getTrigger* = Call_GetTrigger_592155(name: "getTrigger",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                      validator: validate_GetTrigger_592156,
                                      base: "/", url: url_GetTrigger_592157,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_592170 = ref object of OpenApiRestCall_590364
proc url_GetTriggers_592172(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTriggers_592171(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all the triggers associated with a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592173 = query.getOrDefault("MaxResults")
  valid_592173 = validateParameter(valid_592173, JString, required = false,
                                 default = nil)
  if valid_592173 != nil:
    section.add "MaxResults", valid_592173
  var valid_592174 = query.getOrDefault("NextToken")
  valid_592174 = validateParameter(valid_592174, JString, required = false,
                                 default = nil)
  if valid_592174 != nil:
    section.add "NextToken", valid_592174
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592175 = header.getOrDefault("X-Amz-Target")
  valid_592175 = validateParameter(valid_592175, JString, required = true,
                                 default = newJString("AWSGlue.GetTriggers"))
  if valid_592175 != nil:
    section.add "X-Amz-Target", valid_592175
  var valid_592176 = header.getOrDefault("X-Amz-Signature")
  valid_592176 = validateParameter(valid_592176, JString, required = false,
                                 default = nil)
  if valid_592176 != nil:
    section.add "X-Amz-Signature", valid_592176
  var valid_592177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592177 = validateParameter(valid_592177, JString, required = false,
                                 default = nil)
  if valid_592177 != nil:
    section.add "X-Amz-Content-Sha256", valid_592177
  var valid_592178 = header.getOrDefault("X-Amz-Date")
  valid_592178 = validateParameter(valid_592178, JString, required = false,
                                 default = nil)
  if valid_592178 != nil:
    section.add "X-Amz-Date", valid_592178
  var valid_592179 = header.getOrDefault("X-Amz-Credential")
  valid_592179 = validateParameter(valid_592179, JString, required = false,
                                 default = nil)
  if valid_592179 != nil:
    section.add "X-Amz-Credential", valid_592179
  var valid_592180 = header.getOrDefault("X-Amz-Security-Token")
  valid_592180 = validateParameter(valid_592180, JString, required = false,
                                 default = nil)
  if valid_592180 != nil:
    section.add "X-Amz-Security-Token", valid_592180
  var valid_592181 = header.getOrDefault("X-Amz-Algorithm")
  valid_592181 = validateParameter(valid_592181, JString, required = false,
                                 default = nil)
  if valid_592181 != nil:
    section.add "X-Amz-Algorithm", valid_592181
  var valid_592182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592182 = validateParameter(valid_592182, JString, required = false,
                                 default = nil)
  if valid_592182 != nil:
    section.add "X-Amz-SignedHeaders", valid_592182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592184: Call_GetTriggers_592170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_592184.validator(path, query, header, formData, body)
  let scheme = call_592184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592184.url(scheme.get, call_592184.host, call_592184.base,
                         call_592184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592184, url, valid)

proc call*(call_592185: Call_GetTriggers_592170; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592186 = newJObject()
  var body_592187 = newJObject()
  add(query_592186, "MaxResults", newJString(MaxResults))
  add(query_592186, "NextToken", newJString(NextToken))
  if body != nil:
    body_592187 = body
  result = call_592185.call(nil, query_592186, nil, nil, body_592187)

var getTriggers* = Call_GetTriggers_592170(name: "getTriggers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTriggers",
                                        validator: validate_GetTriggers_592171,
                                        base: "/", url: url_GetTriggers_592172,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_592188 = ref object of OpenApiRestCall_590364
proc url_GetUserDefinedFunction_592190(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUserDefinedFunction_592189(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592191 = header.getOrDefault("X-Amz-Target")
  valid_592191 = validateParameter(valid_592191, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_592191 != nil:
    section.add "X-Amz-Target", valid_592191
  var valid_592192 = header.getOrDefault("X-Amz-Signature")
  valid_592192 = validateParameter(valid_592192, JString, required = false,
                                 default = nil)
  if valid_592192 != nil:
    section.add "X-Amz-Signature", valid_592192
  var valid_592193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592193 = validateParameter(valid_592193, JString, required = false,
                                 default = nil)
  if valid_592193 != nil:
    section.add "X-Amz-Content-Sha256", valid_592193
  var valid_592194 = header.getOrDefault("X-Amz-Date")
  valid_592194 = validateParameter(valid_592194, JString, required = false,
                                 default = nil)
  if valid_592194 != nil:
    section.add "X-Amz-Date", valid_592194
  var valid_592195 = header.getOrDefault("X-Amz-Credential")
  valid_592195 = validateParameter(valid_592195, JString, required = false,
                                 default = nil)
  if valid_592195 != nil:
    section.add "X-Amz-Credential", valid_592195
  var valid_592196 = header.getOrDefault("X-Amz-Security-Token")
  valid_592196 = validateParameter(valid_592196, JString, required = false,
                                 default = nil)
  if valid_592196 != nil:
    section.add "X-Amz-Security-Token", valid_592196
  var valid_592197 = header.getOrDefault("X-Amz-Algorithm")
  valid_592197 = validateParameter(valid_592197, JString, required = false,
                                 default = nil)
  if valid_592197 != nil:
    section.add "X-Amz-Algorithm", valid_592197
  var valid_592198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592198 = validateParameter(valid_592198, JString, required = false,
                                 default = nil)
  if valid_592198 != nil:
    section.add "X-Amz-SignedHeaders", valid_592198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592200: Call_GetUserDefinedFunction_592188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_592200.validator(path, query, header, formData, body)
  let scheme = call_592200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592200.url(scheme.get, call_592200.host, call_592200.base,
                         call_592200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592200, url, valid)

proc call*(call_592201: Call_GetUserDefinedFunction_592188; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_592202 = newJObject()
  if body != nil:
    body_592202 = body
  result = call_592201.call(nil, nil, nil, nil, body_592202)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_592188(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_592189, base: "/",
    url: url_GetUserDefinedFunction_592190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_592203 = ref object of OpenApiRestCall_590364
proc url_GetUserDefinedFunctions_592205(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUserDefinedFunctions_592204(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592206 = query.getOrDefault("MaxResults")
  valid_592206 = validateParameter(valid_592206, JString, required = false,
                                 default = nil)
  if valid_592206 != nil:
    section.add "MaxResults", valid_592206
  var valid_592207 = query.getOrDefault("NextToken")
  valid_592207 = validateParameter(valid_592207, JString, required = false,
                                 default = nil)
  if valid_592207 != nil:
    section.add "NextToken", valid_592207
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592208 = header.getOrDefault("X-Amz-Target")
  valid_592208 = validateParameter(valid_592208, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_592208 != nil:
    section.add "X-Amz-Target", valid_592208
  var valid_592209 = header.getOrDefault("X-Amz-Signature")
  valid_592209 = validateParameter(valid_592209, JString, required = false,
                                 default = nil)
  if valid_592209 != nil:
    section.add "X-Amz-Signature", valid_592209
  var valid_592210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592210 = validateParameter(valid_592210, JString, required = false,
                                 default = nil)
  if valid_592210 != nil:
    section.add "X-Amz-Content-Sha256", valid_592210
  var valid_592211 = header.getOrDefault("X-Amz-Date")
  valid_592211 = validateParameter(valid_592211, JString, required = false,
                                 default = nil)
  if valid_592211 != nil:
    section.add "X-Amz-Date", valid_592211
  var valid_592212 = header.getOrDefault("X-Amz-Credential")
  valid_592212 = validateParameter(valid_592212, JString, required = false,
                                 default = nil)
  if valid_592212 != nil:
    section.add "X-Amz-Credential", valid_592212
  var valid_592213 = header.getOrDefault("X-Amz-Security-Token")
  valid_592213 = validateParameter(valid_592213, JString, required = false,
                                 default = nil)
  if valid_592213 != nil:
    section.add "X-Amz-Security-Token", valid_592213
  var valid_592214 = header.getOrDefault("X-Amz-Algorithm")
  valid_592214 = validateParameter(valid_592214, JString, required = false,
                                 default = nil)
  if valid_592214 != nil:
    section.add "X-Amz-Algorithm", valid_592214
  var valid_592215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592215 = validateParameter(valid_592215, JString, required = false,
                                 default = nil)
  if valid_592215 != nil:
    section.add "X-Amz-SignedHeaders", valid_592215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592217: Call_GetUserDefinedFunctions_592203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_592217.validator(path, query, header, formData, body)
  let scheme = call_592217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592217.url(scheme.get, call_592217.host, call_592217.base,
                         call_592217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592217, url, valid)

proc call*(call_592218: Call_GetUserDefinedFunctions_592203; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592219 = newJObject()
  var body_592220 = newJObject()
  add(query_592219, "MaxResults", newJString(MaxResults))
  add(query_592219, "NextToken", newJString(NextToken))
  if body != nil:
    body_592220 = body
  result = call_592218.call(nil, query_592219, nil, nil, body_592220)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_592203(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_592204, base: "/",
    url: url_GetUserDefinedFunctions_592205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_592221 = ref object of OpenApiRestCall_590364
proc url_GetWorkflow_592223(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflow_592222(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves resource metadata for a workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592224 = header.getOrDefault("X-Amz-Target")
  valid_592224 = validateParameter(valid_592224, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflow"))
  if valid_592224 != nil:
    section.add "X-Amz-Target", valid_592224
  var valid_592225 = header.getOrDefault("X-Amz-Signature")
  valid_592225 = validateParameter(valid_592225, JString, required = false,
                                 default = nil)
  if valid_592225 != nil:
    section.add "X-Amz-Signature", valid_592225
  var valid_592226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592226 = validateParameter(valid_592226, JString, required = false,
                                 default = nil)
  if valid_592226 != nil:
    section.add "X-Amz-Content-Sha256", valid_592226
  var valid_592227 = header.getOrDefault("X-Amz-Date")
  valid_592227 = validateParameter(valid_592227, JString, required = false,
                                 default = nil)
  if valid_592227 != nil:
    section.add "X-Amz-Date", valid_592227
  var valid_592228 = header.getOrDefault("X-Amz-Credential")
  valid_592228 = validateParameter(valid_592228, JString, required = false,
                                 default = nil)
  if valid_592228 != nil:
    section.add "X-Amz-Credential", valid_592228
  var valid_592229 = header.getOrDefault("X-Amz-Security-Token")
  valid_592229 = validateParameter(valid_592229, JString, required = false,
                                 default = nil)
  if valid_592229 != nil:
    section.add "X-Amz-Security-Token", valid_592229
  var valid_592230 = header.getOrDefault("X-Amz-Algorithm")
  valid_592230 = validateParameter(valid_592230, JString, required = false,
                                 default = nil)
  if valid_592230 != nil:
    section.add "X-Amz-Algorithm", valid_592230
  var valid_592231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592231 = validateParameter(valid_592231, JString, required = false,
                                 default = nil)
  if valid_592231 != nil:
    section.add "X-Amz-SignedHeaders", valid_592231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592233: Call_GetWorkflow_592221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_592233.validator(path, query, header, formData, body)
  let scheme = call_592233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592233.url(scheme.get, call_592233.host, call_592233.base,
                         call_592233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592233, url, valid)

proc call*(call_592234: Call_GetWorkflow_592221; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_592235 = newJObject()
  if body != nil:
    body_592235 = body
  result = call_592234.call(nil, nil, nil, nil, body_592235)

var getWorkflow* = Call_GetWorkflow_592221(name: "getWorkflow",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
                                        validator: validate_GetWorkflow_592222,
                                        base: "/", url: url_GetWorkflow_592223,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_592236 = ref object of OpenApiRestCall_590364
proc url_GetWorkflowRun_592238(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRun_592237(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592239 = header.getOrDefault("X-Amz-Target")
  valid_592239 = validateParameter(valid_592239, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflowRun"))
  if valid_592239 != nil:
    section.add "X-Amz-Target", valid_592239
  var valid_592240 = header.getOrDefault("X-Amz-Signature")
  valid_592240 = validateParameter(valid_592240, JString, required = false,
                                 default = nil)
  if valid_592240 != nil:
    section.add "X-Amz-Signature", valid_592240
  var valid_592241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592241 = validateParameter(valid_592241, JString, required = false,
                                 default = nil)
  if valid_592241 != nil:
    section.add "X-Amz-Content-Sha256", valid_592241
  var valid_592242 = header.getOrDefault("X-Amz-Date")
  valid_592242 = validateParameter(valid_592242, JString, required = false,
                                 default = nil)
  if valid_592242 != nil:
    section.add "X-Amz-Date", valid_592242
  var valid_592243 = header.getOrDefault("X-Amz-Credential")
  valid_592243 = validateParameter(valid_592243, JString, required = false,
                                 default = nil)
  if valid_592243 != nil:
    section.add "X-Amz-Credential", valid_592243
  var valid_592244 = header.getOrDefault("X-Amz-Security-Token")
  valid_592244 = validateParameter(valid_592244, JString, required = false,
                                 default = nil)
  if valid_592244 != nil:
    section.add "X-Amz-Security-Token", valid_592244
  var valid_592245 = header.getOrDefault("X-Amz-Algorithm")
  valid_592245 = validateParameter(valid_592245, JString, required = false,
                                 default = nil)
  if valid_592245 != nil:
    section.add "X-Amz-Algorithm", valid_592245
  var valid_592246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592246 = validateParameter(valid_592246, JString, required = false,
                                 default = nil)
  if valid_592246 != nil:
    section.add "X-Amz-SignedHeaders", valid_592246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592248: Call_GetWorkflowRun_592236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_592248.validator(path, query, header, formData, body)
  let scheme = call_592248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592248.url(scheme.get, call_592248.host, call_592248.base,
                         call_592248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592248, url, valid)

proc call*(call_592249: Call_GetWorkflowRun_592236; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_592250 = newJObject()
  if body != nil:
    body_592250 = body
  result = call_592249.call(nil, nil, nil, nil, body_592250)

var getWorkflowRun* = Call_GetWorkflowRun_592236(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_592237, base: "/", url: url_GetWorkflowRun_592238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_592251 = ref object of OpenApiRestCall_590364
proc url_GetWorkflowRunProperties_592253(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRunProperties_592252(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592254 = header.getOrDefault("X-Amz-Target")
  valid_592254 = validateParameter(valid_592254, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_592254 != nil:
    section.add "X-Amz-Target", valid_592254
  var valid_592255 = header.getOrDefault("X-Amz-Signature")
  valid_592255 = validateParameter(valid_592255, JString, required = false,
                                 default = nil)
  if valid_592255 != nil:
    section.add "X-Amz-Signature", valid_592255
  var valid_592256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592256 = validateParameter(valid_592256, JString, required = false,
                                 default = nil)
  if valid_592256 != nil:
    section.add "X-Amz-Content-Sha256", valid_592256
  var valid_592257 = header.getOrDefault("X-Amz-Date")
  valid_592257 = validateParameter(valid_592257, JString, required = false,
                                 default = nil)
  if valid_592257 != nil:
    section.add "X-Amz-Date", valid_592257
  var valid_592258 = header.getOrDefault("X-Amz-Credential")
  valid_592258 = validateParameter(valid_592258, JString, required = false,
                                 default = nil)
  if valid_592258 != nil:
    section.add "X-Amz-Credential", valid_592258
  var valid_592259 = header.getOrDefault("X-Amz-Security-Token")
  valid_592259 = validateParameter(valid_592259, JString, required = false,
                                 default = nil)
  if valid_592259 != nil:
    section.add "X-Amz-Security-Token", valid_592259
  var valid_592260 = header.getOrDefault("X-Amz-Algorithm")
  valid_592260 = validateParameter(valid_592260, JString, required = false,
                                 default = nil)
  if valid_592260 != nil:
    section.add "X-Amz-Algorithm", valid_592260
  var valid_592261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592261 = validateParameter(valid_592261, JString, required = false,
                                 default = nil)
  if valid_592261 != nil:
    section.add "X-Amz-SignedHeaders", valid_592261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592263: Call_GetWorkflowRunProperties_592251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_592263.validator(path, query, header, formData, body)
  let scheme = call_592263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592263.url(scheme.get, call_592263.host, call_592263.base,
                         call_592263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592263, url, valid)

proc call*(call_592264: Call_GetWorkflowRunProperties_592251; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_592265 = newJObject()
  if body != nil:
    body_592265 = body
  result = call_592264.call(nil, nil, nil, nil, body_592265)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_592251(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_592252, base: "/",
    url: url_GetWorkflowRunProperties_592253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_592266 = ref object of OpenApiRestCall_590364
proc url_GetWorkflowRuns_592268(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRuns_592267(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592269 = query.getOrDefault("MaxResults")
  valid_592269 = validateParameter(valid_592269, JString, required = false,
                                 default = nil)
  if valid_592269 != nil:
    section.add "MaxResults", valid_592269
  var valid_592270 = query.getOrDefault("NextToken")
  valid_592270 = validateParameter(valid_592270, JString, required = false,
                                 default = nil)
  if valid_592270 != nil:
    section.add "NextToken", valid_592270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592271 = header.getOrDefault("X-Amz-Target")
  valid_592271 = validateParameter(valid_592271, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_592271 != nil:
    section.add "X-Amz-Target", valid_592271
  var valid_592272 = header.getOrDefault("X-Amz-Signature")
  valid_592272 = validateParameter(valid_592272, JString, required = false,
                                 default = nil)
  if valid_592272 != nil:
    section.add "X-Amz-Signature", valid_592272
  var valid_592273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592273 = validateParameter(valid_592273, JString, required = false,
                                 default = nil)
  if valid_592273 != nil:
    section.add "X-Amz-Content-Sha256", valid_592273
  var valid_592274 = header.getOrDefault("X-Amz-Date")
  valid_592274 = validateParameter(valid_592274, JString, required = false,
                                 default = nil)
  if valid_592274 != nil:
    section.add "X-Amz-Date", valid_592274
  var valid_592275 = header.getOrDefault("X-Amz-Credential")
  valid_592275 = validateParameter(valid_592275, JString, required = false,
                                 default = nil)
  if valid_592275 != nil:
    section.add "X-Amz-Credential", valid_592275
  var valid_592276 = header.getOrDefault("X-Amz-Security-Token")
  valid_592276 = validateParameter(valid_592276, JString, required = false,
                                 default = nil)
  if valid_592276 != nil:
    section.add "X-Amz-Security-Token", valid_592276
  var valid_592277 = header.getOrDefault("X-Amz-Algorithm")
  valid_592277 = validateParameter(valid_592277, JString, required = false,
                                 default = nil)
  if valid_592277 != nil:
    section.add "X-Amz-Algorithm", valid_592277
  var valid_592278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592278 = validateParameter(valid_592278, JString, required = false,
                                 default = nil)
  if valid_592278 != nil:
    section.add "X-Amz-SignedHeaders", valid_592278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592280: Call_GetWorkflowRuns_592266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_592280.validator(path, query, header, formData, body)
  let scheme = call_592280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592280.url(scheme.get, call_592280.host, call_592280.base,
                         call_592280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592280, url, valid)

proc call*(call_592281: Call_GetWorkflowRuns_592266; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592282 = newJObject()
  var body_592283 = newJObject()
  add(query_592282, "MaxResults", newJString(MaxResults))
  add(query_592282, "NextToken", newJString(NextToken))
  if body != nil:
    body_592283 = body
  result = call_592281.call(nil, query_592282, nil, nil, body_592283)

var getWorkflowRuns* = Call_GetWorkflowRuns_592266(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_592267, base: "/", url: url_GetWorkflowRuns_592268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_592284 = ref object of OpenApiRestCall_590364
proc url_ImportCatalogToGlue_592286(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportCatalogToGlue_592285(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592287 = header.getOrDefault("X-Amz-Target")
  valid_592287 = validateParameter(valid_592287, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_592287 != nil:
    section.add "X-Amz-Target", valid_592287
  var valid_592288 = header.getOrDefault("X-Amz-Signature")
  valid_592288 = validateParameter(valid_592288, JString, required = false,
                                 default = nil)
  if valid_592288 != nil:
    section.add "X-Amz-Signature", valid_592288
  var valid_592289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592289 = validateParameter(valid_592289, JString, required = false,
                                 default = nil)
  if valid_592289 != nil:
    section.add "X-Amz-Content-Sha256", valid_592289
  var valid_592290 = header.getOrDefault("X-Amz-Date")
  valid_592290 = validateParameter(valid_592290, JString, required = false,
                                 default = nil)
  if valid_592290 != nil:
    section.add "X-Amz-Date", valid_592290
  var valid_592291 = header.getOrDefault("X-Amz-Credential")
  valid_592291 = validateParameter(valid_592291, JString, required = false,
                                 default = nil)
  if valid_592291 != nil:
    section.add "X-Amz-Credential", valid_592291
  var valid_592292 = header.getOrDefault("X-Amz-Security-Token")
  valid_592292 = validateParameter(valid_592292, JString, required = false,
                                 default = nil)
  if valid_592292 != nil:
    section.add "X-Amz-Security-Token", valid_592292
  var valid_592293 = header.getOrDefault("X-Amz-Algorithm")
  valid_592293 = validateParameter(valid_592293, JString, required = false,
                                 default = nil)
  if valid_592293 != nil:
    section.add "X-Amz-Algorithm", valid_592293
  var valid_592294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592294 = validateParameter(valid_592294, JString, required = false,
                                 default = nil)
  if valid_592294 != nil:
    section.add "X-Amz-SignedHeaders", valid_592294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592296: Call_ImportCatalogToGlue_592284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_592296.validator(path, query, header, formData, body)
  let scheme = call_592296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592296.url(scheme.get, call_592296.host, call_592296.base,
                         call_592296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592296, url, valid)

proc call*(call_592297: Call_ImportCatalogToGlue_592284; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_592298 = newJObject()
  if body != nil:
    body_592298 = body
  result = call_592297.call(nil, nil, nil, nil, body_592298)

var importCatalogToGlue* = Call_ImportCatalogToGlue_592284(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_592285, base: "/",
    url: url_ImportCatalogToGlue_592286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_592299 = ref object of OpenApiRestCall_590364
proc url_ListCrawlers_592301(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCrawlers_592300(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592302 = query.getOrDefault("MaxResults")
  valid_592302 = validateParameter(valid_592302, JString, required = false,
                                 default = nil)
  if valid_592302 != nil:
    section.add "MaxResults", valid_592302
  var valid_592303 = query.getOrDefault("NextToken")
  valid_592303 = validateParameter(valid_592303, JString, required = false,
                                 default = nil)
  if valid_592303 != nil:
    section.add "NextToken", valid_592303
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592304 = header.getOrDefault("X-Amz-Target")
  valid_592304 = validateParameter(valid_592304, JString, required = true,
                                 default = newJString("AWSGlue.ListCrawlers"))
  if valid_592304 != nil:
    section.add "X-Amz-Target", valid_592304
  var valid_592305 = header.getOrDefault("X-Amz-Signature")
  valid_592305 = validateParameter(valid_592305, JString, required = false,
                                 default = nil)
  if valid_592305 != nil:
    section.add "X-Amz-Signature", valid_592305
  var valid_592306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592306 = validateParameter(valid_592306, JString, required = false,
                                 default = nil)
  if valid_592306 != nil:
    section.add "X-Amz-Content-Sha256", valid_592306
  var valid_592307 = header.getOrDefault("X-Amz-Date")
  valid_592307 = validateParameter(valid_592307, JString, required = false,
                                 default = nil)
  if valid_592307 != nil:
    section.add "X-Amz-Date", valid_592307
  var valid_592308 = header.getOrDefault("X-Amz-Credential")
  valid_592308 = validateParameter(valid_592308, JString, required = false,
                                 default = nil)
  if valid_592308 != nil:
    section.add "X-Amz-Credential", valid_592308
  var valid_592309 = header.getOrDefault("X-Amz-Security-Token")
  valid_592309 = validateParameter(valid_592309, JString, required = false,
                                 default = nil)
  if valid_592309 != nil:
    section.add "X-Amz-Security-Token", valid_592309
  var valid_592310 = header.getOrDefault("X-Amz-Algorithm")
  valid_592310 = validateParameter(valid_592310, JString, required = false,
                                 default = nil)
  if valid_592310 != nil:
    section.add "X-Amz-Algorithm", valid_592310
  var valid_592311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592311 = validateParameter(valid_592311, JString, required = false,
                                 default = nil)
  if valid_592311 != nil:
    section.add "X-Amz-SignedHeaders", valid_592311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592313: Call_ListCrawlers_592299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_592313.validator(path, query, header, formData, body)
  let scheme = call_592313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592313.url(scheme.get, call_592313.host, call_592313.base,
                         call_592313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592313, url, valid)

proc call*(call_592314: Call_ListCrawlers_592299; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592315 = newJObject()
  var body_592316 = newJObject()
  add(query_592315, "MaxResults", newJString(MaxResults))
  add(query_592315, "NextToken", newJString(NextToken))
  if body != nil:
    body_592316 = body
  result = call_592314.call(nil, query_592315, nil, nil, body_592316)

var listCrawlers* = Call_ListCrawlers_592299(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_592300, base: "/", url: url_ListCrawlers_592301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_592317 = ref object of OpenApiRestCall_590364
proc url_ListDevEndpoints_592319(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevEndpoints_592318(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592320 = query.getOrDefault("MaxResults")
  valid_592320 = validateParameter(valid_592320, JString, required = false,
                                 default = nil)
  if valid_592320 != nil:
    section.add "MaxResults", valid_592320
  var valid_592321 = query.getOrDefault("NextToken")
  valid_592321 = validateParameter(valid_592321, JString, required = false,
                                 default = nil)
  if valid_592321 != nil:
    section.add "NextToken", valid_592321
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592322 = header.getOrDefault("X-Amz-Target")
  valid_592322 = validateParameter(valid_592322, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_592322 != nil:
    section.add "X-Amz-Target", valid_592322
  var valid_592323 = header.getOrDefault("X-Amz-Signature")
  valid_592323 = validateParameter(valid_592323, JString, required = false,
                                 default = nil)
  if valid_592323 != nil:
    section.add "X-Amz-Signature", valid_592323
  var valid_592324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592324 = validateParameter(valid_592324, JString, required = false,
                                 default = nil)
  if valid_592324 != nil:
    section.add "X-Amz-Content-Sha256", valid_592324
  var valid_592325 = header.getOrDefault("X-Amz-Date")
  valid_592325 = validateParameter(valid_592325, JString, required = false,
                                 default = nil)
  if valid_592325 != nil:
    section.add "X-Amz-Date", valid_592325
  var valid_592326 = header.getOrDefault("X-Amz-Credential")
  valid_592326 = validateParameter(valid_592326, JString, required = false,
                                 default = nil)
  if valid_592326 != nil:
    section.add "X-Amz-Credential", valid_592326
  var valid_592327 = header.getOrDefault("X-Amz-Security-Token")
  valid_592327 = validateParameter(valid_592327, JString, required = false,
                                 default = nil)
  if valid_592327 != nil:
    section.add "X-Amz-Security-Token", valid_592327
  var valid_592328 = header.getOrDefault("X-Amz-Algorithm")
  valid_592328 = validateParameter(valid_592328, JString, required = false,
                                 default = nil)
  if valid_592328 != nil:
    section.add "X-Amz-Algorithm", valid_592328
  var valid_592329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592329 = validateParameter(valid_592329, JString, required = false,
                                 default = nil)
  if valid_592329 != nil:
    section.add "X-Amz-SignedHeaders", valid_592329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592331: Call_ListDevEndpoints_592317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_592331.validator(path, query, header, formData, body)
  let scheme = call_592331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592331.url(scheme.get, call_592331.host, call_592331.base,
                         call_592331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592331, url, valid)

proc call*(call_592332: Call_ListDevEndpoints_592317; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592333 = newJObject()
  var body_592334 = newJObject()
  add(query_592333, "MaxResults", newJString(MaxResults))
  add(query_592333, "NextToken", newJString(NextToken))
  if body != nil:
    body_592334 = body
  result = call_592332.call(nil, query_592333, nil, nil, body_592334)

var listDevEndpoints* = Call_ListDevEndpoints_592317(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_592318, base: "/",
    url: url_ListDevEndpoints_592319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_592335 = ref object of OpenApiRestCall_590364
proc url_ListJobs_592337(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_592336(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592338 = query.getOrDefault("MaxResults")
  valid_592338 = validateParameter(valid_592338, JString, required = false,
                                 default = nil)
  if valid_592338 != nil:
    section.add "MaxResults", valid_592338
  var valid_592339 = query.getOrDefault("NextToken")
  valid_592339 = validateParameter(valid_592339, JString, required = false,
                                 default = nil)
  if valid_592339 != nil:
    section.add "NextToken", valid_592339
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592340 = header.getOrDefault("X-Amz-Target")
  valid_592340 = validateParameter(valid_592340, JString, required = true,
                                 default = newJString("AWSGlue.ListJobs"))
  if valid_592340 != nil:
    section.add "X-Amz-Target", valid_592340
  var valid_592341 = header.getOrDefault("X-Amz-Signature")
  valid_592341 = validateParameter(valid_592341, JString, required = false,
                                 default = nil)
  if valid_592341 != nil:
    section.add "X-Amz-Signature", valid_592341
  var valid_592342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592342 = validateParameter(valid_592342, JString, required = false,
                                 default = nil)
  if valid_592342 != nil:
    section.add "X-Amz-Content-Sha256", valid_592342
  var valid_592343 = header.getOrDefault("X-Amz-Date")
  valid_592343 = validateParameter(valid_592343, JString, required = false,
                                 default = nil)
  if valid_592343 != nil:
    section.add "X-Amz-Date", valid_592343
  var valid_592344 = header.getOrDefault("X-Amz-Credential")
  valid_592344 = validateParameter(valid_592344, JString, required = false,
                                 default = nil)
  if valid_592344 != nil:
    section.add "X-Amz-Credential", valid_592344
  var valid_592345 = header.getOrDefault("X-Amz-Security-Token")
  valid_592345 = validateParameter(valid_592345, JString, required = false,
                                 default = nil)
  if valid_592345 != nil:
    section.add "X-Amz-Security-Token", valid_592345
  var valid_592346 = header.getOrDefault("X-Amz-Algorithm")
  valid_592346 = validateParameter(valid_592346, JString, required = false,
                                 default = nil)
  if valid_592346 != nil:
    section.add "X-Amz-Algorithm", valid_592346
  var valid_592347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592347 = validateParameter(valid_592347, JString, required = false,
                                 default = nil)
  if valid_592347 != nil:
    section.add "X-Amz-SignedHeaders", valid_592347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592349: Call_ListJobs_592335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_592349.validator(path, query, header, formData, body)
  let scheme = call_592349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592349.url(scheme.get, call_592349.host, call_592349.base,
                         call_592349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592349, url, valid)

proc call*(call_592350: Call_ListJobs_592335; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592351 = newJObject()
  var body_592352 = newJObject()
  add(query_592351, "MaxResults", newJString(MaxResults))
  add(query_592351, "NextToken", newJString(NextToken))
  if body != nil:
    body_592352 = body
  result = call_592350.call(nil, query_592351, nil, nil, body_592352)

var listJobs* = Call_ListJobs_592335(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                  validator: validate_ListJobs_592336, base: "/",
                                  url: url_ListJobs_592337,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_592353 = ref object of OpenApiRestCall_590364
proc url_ListTriggers_592355(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTriggers_592354(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592356 = query.getOrDefault("MaxResults")
  valid_592356 = validateParameter(valid_592356, JString, required = false,
                                 default = nil)
  if valid_592356 != nil:
    section.add "MaxResults", valid_592356
  var valid_592357 = query.getOrDefault("NextToken")
  valid_592357 = validateParameter(valid_592357, JString, required = false,
                                 default = nil)
  if valid_592357 != nil:
    section.add "NextToken", valid_592357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592358 = header.getOrDefault("X-Amz-Target")
  valid_592358 = validateParameter(valid_592358, JString, required = true,
                                 default = newJString("AWSGlue.ListTriggers"))
  if valid_592358 != nil:
    section.add "X-Amz-Target", valid_592358
  var valid_592359 = header.getOrDefault("X-Amz-Signature")
  valid_592359 = validateParameter(valid_592359, JString, required = false,
                                 default = nil)
  if valid_592359 != nil:
    section.add "X-Amz-Signature", valid_592359
  var valid_592360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592360 = validateParameter(valid_592360, JString, required = false,
                                 default = nil)
  if valid_592360 != nil:
    section.add "X-Amz-Content-Sha256", valid_592360
  var valid_592361 = header.getOrDefault("X-Amz-Date")
  valid_592361 = validateParameter(valid_592361, JString, required = false,
                                 default = nil)
  if valid_592361 != nil:
    section.add "X-Amz-Date", valid_592361
  var valid_592362 = header.getOrDefault("X-Amz-Credential")
  valid_592362 = validateParameter(valid_592362, JString, required = false,
                                 default = nil)
  if valid_592362 != nil:
    section.add "X-Amz-Credential", valid_592362
  var valid_592363 = header.getOrDefault("X-Amz-Security-Token")
  valid_592363 = validateParameter(valid_592363, JString, required = false,
                                 default = nil)
  if valid_592363 != nil:
    section.add "X-Amz-Security-Token", valid_592363
  var valid_592364 = header.getOrDefault("X-Amz-Algorithm")
  valid_592364 = validateParameter(valid_592364, JString, required = false,
                                 default = nil)
  if valid_592364 != nil:
    section.add "X-Amz-Algorithm", valid_592364
  var valid_592365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592365 = validateParameter(valid_592365, JString, required = false,
                                 default = nil)
  if valid_592365 != nil:
    section.add "X-Amz-SignedHeaders", valid_592365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592367: Call_ListTriggers_592353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_592367.validator(path, query, header, formData, body)
  let scheme = call_592367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592367.url(scheme.get, call_592367.host, call_592367.base,
                         call_592367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592367, url, valid)

proc call*(call_592368: Call_ListTriggers_592353; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592369 = newJObject()
  var body_592370 = newJObject()
  add(query_592369, "MaxResults", newJString(MaxResults))
  add(query_592369, "NextToken", newJString(NextToken))
  if body != nil:
    body_592370 = body
  result = call_592368.call(nil, query_592369, nil, nil, body_592370)

var listTriggers* = Call_ListTriggers_592353(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_592354, base: "/", url: url_ListTriggers_592355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_592371 = ref object of OpenApiRestCall_590364
proc url_ListWorkflows_592373(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkflows_592372(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists names of workflows created in the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592374 = query.getOrDefault("MaxResults")
  valid_592374 = validateParameter(valid_592374, JString, required = false,
                                 default = nil)
  if valid_592374 != nil:
    section.add "MaxResults", valid_592374
  var valid_592375 = query.getOrDefault("NextToken")
  valid_592375 = validateParameter(valid_592375, JString, required = false,
                                 default = nil)
  if valid_592375 != nil:
    section.add "NextToken", valid_592375
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592376 = header.getOrDefault("X-Amz-Target")
  valid_592376 = validateParameter(valid_592376, JString, required = true,
                                 default = newJString("AWSGlue.ListWorkflows"))
  if valid_592376 != nil:
    section.add "X-Amz-Target", valid_592376
  var valid_592377 = header.getOrDefault("X-Amz-Signature")
  valid_592377 = validateParameter(valid_592377, JString, required = false,
                                 default = nil)
  if valid_592377 != nil:
    section.add "X-Amz-Signature", valid_592377
  var valid_592378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592378 = validateParameter(valid_592378, JString, required = false,
                                 default = nil)
  if valid_592378 != nil:
    section.add "X-Amz-Content-Sha256", valid_592378
  var valid_592379 = header.getOrDefault("X-Amz-Date")
  valid_592379 = validateParameter(valid_592379, JString, required = false,
                                 default = nil)
  if valid_592379 != nil:
    section.add "X-Amz-Date", valid_592379
  var valid_592380 = header.getOrDefault("X-Amz-Credential")
  valid_592380 = validateParameter(valid_592380, JString, required = false,
                                 default = nil)
  if valid_592380 != nil:
    section.add "X-Amz-Credential", valid_592380
  var valid_592381 = header.getOrDefault("X-Amz-Security-Token")
  valid_592381 = validateParameter(valid_592381, JString, required = false,
                                 default = nil)
  if valid_592381 != nil:
    section.add "X-Amz-Security-Token", valid_592381
  var valid_592382 = header.getOrDefault("X-Amz-Algorithm")
  valid_592382 = validateParameter(valid_592382, JString, required = false,
                                 default = nil)
  if valid_592382 != nil:
    section.add "X-Amz-Algorithm", valid_592382
  var valid_592383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592383 = validateParameter(valid_592383, JString, required = false,
                                 default = nil)
  if valid_592383 != nil:
    section.add "X-Amz-SignedHeaders", valid_592383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592385: Call_ListWorkflows_592371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_592385.validator(path, query, header, formData, body)
  let scheme = call_592385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592385.url(scheme.get, call_592385.host, call_592385.base,
                         call_592385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592385, url, valid)

proc call*(call_592386: Call_ListWorkflows_592371; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592387 = newJObject()
  var body_592388 = newJObject()
  add(query_592387, "MaxResults", newJString(MaxResults))
  add(query_592387, "NextToken", newJString(NextToken))
  if body != nil:
    body_592388 = body
  result = call_592386.call(nil, query_592387, nil, nil, body_592388)

var listWorkflows* = Call_ListWorkflows_592371(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_592372, base: "/", url: url_ListWorkflows_592373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_592389 = ref object of OpenApiRestCall_590364
proc url_PutDataCatalogEncryptionSettings_592391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDataCatalogEncryptionSettings_592390(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592392 = header.getOrDefault("X-Amz-Target")
  valid_592392 = validateParameter(valid_592392, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_592392 != nil:
    section.add "X-Amz-Target", valid_592392
  var valid_592393 = header.getOrDefault("X-Amz-Signature")
  valid_592393 = validateParameter(valid_592393, JString, required = false,
                                 default = nil)
  if valid_592393 != nil:
    section.add "X-Amz-Signature", valid_592393
  var valid_592394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592394 = validateParameter(valid_592394, JString, required = false,
                                 default = nil)
  if valid_592394 != nil:
    section.add "X-Amz-Content-Sha256", valid_592394
  var valid_592395 = header.getOrDefault("X-Amz-Date")
  valid_592395 = validateParameter(valid_592395, JString, required = false,
                                 default = nil)
  if valid_592395 != nil:
    section.add "X-Amz-Date", valid_592395
  var valid_592396 = header.getOrDefault("X-Amz-Credential")
  valid_592396 = validateParameter(valid_592396, JString, required = false,
                                 default = nil)
  if valid_592396 != nil:
    section.add "X-Amz-Credential", valid_592396
  var valid_592397 = header.getOrDefault("X-Amz-Security-Token")
  valid_592397 = validateParameter(valid_592397, JString, required = false,
                                 default = nil)
  if valid_592397 != nil:
    section.add "X-Amz-Security-Token", valid_592397
  var valid_592398 = header.getOrDefault("X-Amz-Algorithm")
  valid_592398 = validateParameter(valid_592398, JString, required = false,
                                 default = nil)
  if valid_592398 != nil:
    section.add "X-Amz-Algorithm", valid_592398
  var valid_592399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592399 = validateParameter(valid_592399, JString, required = false,
                                 default = nil)
  if valid_592399 != nil:
    section.add "X-Amz-SignedHeaders", valid_592399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592401: Call_PutDataCatalogEncryptionSettings_592389;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_592401.validator(path, query, header, formData, body)
  let scheme = call_592401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592401.url(scheme.get, call_592401.host, call_592401.base,
                         call_592401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592401, url, valid)

proc call*(call_592402: Call_PutDataCatalogEncryptionSettings_592389;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_592403 = newJObject()
  if body != nil:
    body_592403 = body
  result = call_592402.call(nil, nil, nil, nil, body_592403)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_592389(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_592390, base: "/",
    url: url_PutDataCatalogEncryptionSettings_592391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_592404 = ref object of OpenApiRestCall_590364
proc url_PutResourcePolicy_592406(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutResourcePolicy_592405(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592407 = header.getOrDefault("X-Amz-Target")
  valid_592407 = validateParameter(valid_592407, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_592407 != nil:
    section.add "X-Amz-Target", valid_592407
  var valid_592408 = header.getOrDefault("X-Amz-Signature")
  valid_592408 = validateParameter(valid_592408, JString, required = false,
                                 default = nil)
  if valid_592408 != nil:
    section.add "X-Amz-Signature", valid_592408
  var valid_592409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592409 = validateParameter(valid_592409, JString, required = false,
                                 default = nil)
  if valid_592409 != nil:
    section.add "X-Amz-Content-Sha256", valid_592409
  var valid_592410 = header.getOrDefault("X-Amz-Date")
  valid_592410 = validateParameter(valid_592410, JString, required = false,
                                 default = nil)
  if valid_592410 != nil:
    section.add "X-Amz-Date", valid_592410
  var valid_592411 = header.getOrDefault("X-Amz-Credential")
  valid_592411 = validateParameter(valid_592411, JString, required = false,
                                 default = nil)
  if valid_592411 != nil:
    section.add "X-Amz-Credential", valid_592411
  var valid_592412 = header.getOrDefault("X-Amz-Security-Token")
  valid_592412 = validateParameter(valid_592412, JString, required = false,
                                 default = nil)
  if valid_592412 != nil:
    section.add "X-Amz-Security-Token", valid_592412
  var valid_592413 = header.getOrDefault("X-Amz-Algorithm")
  valid_592413 = validateParameter(valid_592413, JString, required = false,
                                 default = nil)
  if valid_592413 != nil:
    section.add "X-Amz-Algorithm", valid_592413
  var valid_592414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592414 = validateParameter(valid_592414, JString, required = false,
                                 default = nil)
  if valid_592414 != nil:
    section.add "X-Amz-SignedHeaders", valid_592414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592416: Call_PutResourcePolicy_592404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_592416.validator(path, query, header, formData, body)
  let scheme = call_592416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592416.url(scheme.get, call_592416.host, call_592416.base,
                         call_592416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592416, url, valid)

proc call*(call_592417: Call_PutResourcePolicy_592404; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_592418 = newJObject()
  if body != nil:
    body_592418 = body
  result = call_592417.call(nil, nil, nil, nil, body_592418)

var putResourcePolicy* = Call_PutResourcePolicy_592404(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_592405, base: "/",
    url: url_PutResourcePolicy_592406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_592419 = ref object of OpenApiRestCall_590364
proc url_PutWorkflowRunProperties_592421(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutWorkflowRunProperties_592420(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592422 = header.getOrDefault("X-Amz-Target")
  valid_592422 = validateParameter(valid_592422, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_592422 != nil:
    section.add "X-Amz-Target", valid_592422
  var valid_592423 = header.getOrDefault("X-Amz-Signature")
  valid_592423 = validateParameter(valid_592423, JString, required = false,
                                 default = nil)
  if valid_592423 != nil:
    section.add "X-Amz-Signature", valid_592423
  var valid_592424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592424 = validateParameter(valid_592424, JString, required = false,
                                 default = nil)
  if valid_592424 != nil:
    section.add "X-Amz-Content-Sha256", valid_592424
  var valid_592425 = header.getOrDefault("X-Amz-Date")
  valid_592425 = validateParameter(valid_592425, JString, required = false,
                                 default = nil)
  if valid_592425 != nil:
    section.add "X-Amz-Date", valid_592425
  var valid_592426 = header.getOrDefault("X-Amz-Credential")
  valid_592426 = validateParameter(valid_592426, JString, required = false,
                                 default = nil)
  if valid_592426 != nil:
    section.add "X-Amz-Credential", valid_592426
  var valid_592427 = header.getOrDefault("X-Amz-Security-Token")
  valid_592427 = validateParameter(valid_592427, JString, required = false,
                                 default = nil)
  if valid_592427 != nil:
    section.add "X-Amz-Security-Token", valid_592427
  var valid_592428 = header.getOrDefault("X-Amz-Algorithm")
  valid_592428 = validateParameter(valid_592428, JString, required = false,
                                 default = nil)
  if valid_592428 != nil:
    section.add "X-Amz-Algorithm", valid_592428
  var valid_592429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592429 = validateParameter(valid_592429, JString, required = false,
                                 default = nil)
  if valid_592429 != nil:
    section.add "X-Amz-SignedHeaders", valid_592429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592431: Call_PutWorkflowRunProperties_592419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_592431.validator(path, query, header, formData, body)
  let scheme = call_592431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592431.url(scheme.get, call_592431.host, call_592431.base,
                         call_592431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592431, url, valid)

proc call*(call_592432: Call_PutWorkflowRunProperties_592419; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_592433 = newJObject()
  if body != nil:
    body_592433 = body
  result = call_592432.call(nil, nil, nil, nil, body_592433)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_592419(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_592420, base: "/",
    url: url_PutWorkflowRunProperties_592421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_592434 = ref object of OpenApiRestCall_590364
proc url_ResetJobBookmark_592436(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResetJobBookmark_592435(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Resets a bookmark entry.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592437 = header.getOrDefault("X-Amz-Target")
  valid_592437 = validateParameter(valid_592437, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_592437 != nil:
    section.add "X-Amz-Target", valid_592437
  var valid_592438 = header.getOrDefault("X-Amz-Signature")
  valid_592438 = validateParameter(valid_592438, JString, required = false,
                                 default = nil)
  if valid_592438 != nil:
    section.add "X-Amz-Signature", valid_592438
  var valid_592439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592439 = validateParameter(valid_592439, JString, required = false,
                                 default = nil)
  if valid_592439 != nil:
    section.add "X-Amz-Content-Sha256", valid_592439
  var valid_592440 = header.getOrDefault("X-Amz-Date")
  valid_592440 = validateParameter(valid_592440, JString, required = false,
                                 default = nil)
  if valid_592440 != nil:
    section.add "X-Amz-Date", valid_592440
  var valid_592441 = header.getOrDefault("X-Amz-Credential")
  valid_592441 = validateParameter(valid_592441, JString, required = false,
                                 default = nil)
  if valid_592441 != nil:
    section.add "X-Amz-Credential", valid_592441
  var valid_592442 = header.getOrDefault("X-Amz-Security-Token")
  valid_592442 = validateParameter(valid_592442, JString, required = false,
                                 default = nil)
  if valid_592442 != nil:
    section.add "X-Amz-Security-Token", valid_592442
  var valid_592443 = header.getOrDefault("X-Amz-Algorithm")
  valid_592443 = validateParameter(valid_592443, JString, required = false,
                                 default = nil)
  if valid_592443 != nil:
    section.add "X-Amz-Algorithm", valid_592443
  var valid_592444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592444 = validateParameter(valid_592444, JString, required = false,
                                 default = nil)
  if valid_592444 != nil:
    section.add "X-Amz-SignedHeaders", valid_592444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592446: Call_ResetJobBookmark_592434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_592446.validator(path, query, header, formData, body)
  let scheme = call_592446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592446.url(scheme.get, call_592446.host, call_592446.base,
                         call_592446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592446, url, valid)

proc call*(call_592447: Call_ResetJobBookmark_592434; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_592448 = newJObject()
  if body != nil:
    body_592448 = body
  result = call_592447.call(nil, nil, nil, nil, body_592448)

var resetJobBookmark* = Call_ResetJobBookmark_592434(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_592435, base: "/",
    url: url_ResetJobBookmark_592436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_592449 = ref object of OpenApiRestCall_590364
proc url_SearchTables_592451(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchTables_592450(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_592452 = query.getOrDefault("MaxResults")
  valid_592452 = validateParameter(valid_592452, JString, required = false,
                                 default = nil)
  if valid_592452 != nil:
    section.add "MaxResults", valid_592452
  var valid_592453 = query.getOrDefault("NextToken")
  valid_592453 = validateParameter(valid_592453, JString, required = false,
                                 default = nil)
  if valid_592453 != nil:
    section.add "NextToken", valid_592453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592454 = header.getOrDefault("X-Amz-Target")
  valid_592454 = validateParameter(valid_592454, JString, required = true,
                                 default = newJString("AWSGlue.SearchTables"))
  if valid_592454 != nil:
    section.add "X-Amz-Target", valid_592454
  var valid_592455 = header.getOrDefault("X-Amz-Signature")
  valid_592455 = validateParameter(valid_592455, JString, required = false,
                                 default = nil)
  if valid_592455 != nil:
    section.add "X-Amz-Signature", valid_592455
  var valid_592456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592456 = validateParameter(valid_592456, JString, required = false,
                                 default = nil)
  if valid_592456 != nil:
    section.add "X-Amz-Content-Sha256", valid_592456
  var valid_592457 = header.getOrDefault("X-Amz-Date")
  valid_592457 = validateParameter(valid_592457, JString, required = false,
                                 default = nil)
  if valid_592457 != nil:
    section.add "X-Amz-Date", valid_592457
  var valid_592458 = header.getOrDefault("X-Amz-Credential")
  valid_592458 = validateParameter(valid_592458, JString, required = false,
                                 default = nil)
  if valid_592458 != nil:
    section.add "X-Amz-Credential", valid_592458
  var valid_592459 = header.getOrDefault("X-Amz-Security-Token")
  valid_592459 = validateParameter(valid_592459, JString, required = false,
                                 default = nil)
  if valid_592459 != nil:
    section.add "X-Amz-Security-Token", valid_592459
  var valid_592460 = header.getOrDefault("X-Amz-Algorithm")
  valid_592460 = validateParameter(valid_592460, JString, required = false,
                                 default = nil)
  if valid_592460 != nil:
    section.add "X-Amz-Algorithm", valid_592460
  var valid_592461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592461 = validateParameter(valid_592461, JString, required = false,
                                 default = nil)
  if valid_592461 != nil:
    section.add "X-Amz-SignedHeaders", valid_592461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592463: Call_SearchTables_592449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_592463.validator(path, query, header, formData, body)
  let scheme = call_592463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592463.url(scheme.get, call_592463.host, call_592463.base,
                         call_592463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592463, url, valid)

proc call*(call_592464: Call_SearchTables_592449; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592465 = newJObject()
  var body_592466 = newJObject()
  add(query_592465, "MaxResults", newJString(MaxResults))
  add(query_592465, "NextToken", newJString(NextToken))
  if body != nil:
    body_592466 = body
  result = call_592464.call(nil, query_592465, nil, nil, body_592466)

var searchTables* = Call_SearchTables_592449(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_592450, base: "/", url: url_SearchTables_592451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_592467 = ref object of OpenApiRestCall_590364
proc url_StartCrawler_592469(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartCrawler_592468(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592470 = header.getOrDefault("X-Amz-Target")
  valid_592470 = validateParameter(valid_592470, JString, required = true,
                                 default = newJString("AWSGlue.StartCrawler"))
  if valid_592470 != nil:
    section.add "X-Amz-Target", valid_592470
  var valid_592471 = header.getOrDefault("X-Amz-Signature")
  valid_592471 = validateParameter(valid_592471, JString, required = false,
                                 default = nil)
  if valid_592471 != nil:
    section.add "X-Amz-Signature", valid_592471
  var valid_592472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592472 = validateParameter(valid_592472, JString, required = false,
                                 default = nil)
  if valid_592472 != nil:
    section.add "X-Amz-Content-Sha256", valid_592472
  var valid_592473 = header.getOrDefault("X-Amz-Date")
  valid_592473 = validateParameter(valid_592473, JString, required = false,
                                 default = nil)
  if valid_592473 != nil:
    section.add "X-Amz-Date", valid_592473
  var valid_592474 = header.getOrDefault("X-Amz-Credential")
  valid_592474 = validateParameter(valid_592474, JString, required = false,
                                 default = nil)
  if valid_592474 != nil:
    section.add "X-Amz-Credential", valid_592474
  var valid_592475 = header.getOrDefault("X-Amz-Security-Token")
  valid_592475 = validateParameter(valid_592475, JString, required = false,
                                 default = nil)
  if valid_592475 != nil:
    section.add "X-Amz-Security-Token", valid_592475
  var valid_592476 = header.getOrDefault("X-Amz-Algorithm")
  valid_592476 = validateParameter(valid_592476, JString, required = false,
                                 default = nil)
  if valid_592476 != nil:
    section.add "X-Amz-Algorithm", valid_592476
  var valid_592477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592477 = validateParameter(valid_592477, JString, required = false,
                                 default = nil)
  if valid_592477 != nil:
    section.add "X-Amz-SignedHeaders", valid_592477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592479: Call_StartCrawler_592467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_592479.validator(path, query, header, formData, body)
  let scheme = call_592479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592479.url(scheme.get, call_592479.host, call_592479.base,
                         call_592479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592479, url, valid)

proc call*(call_592480: Call_StartCrawler_592467; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_592481 = newJObject()
  if body != nil:
    body_592481 = body
  result = call_592480.call(nil, nil, nil, nil, body_592481)

var startCrawler* = Call_StartCrawler_592467(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_592468, base: "/", url: url_StartCrawler_592469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_592482 = ref object of OpenApiRestCall_590364
proc url_StartCrawlerSchedule_592484(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartCrawlerSchedule_592483(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592485 = header.getOrDefault("X-Amz-Target")
  valid_592485 = validateParameter(valid_592485, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_592485 != nil:
    section.add "X-Amz-Target", valid_592485
  var valid_592486 = header.getOrDefault("X-Amz-Signature")
  valid_592486 = validateParameter(valid_592486, JString, required = false,
                                 default = nil)
  if valid_592486 != nil:
    section.add "X-Amz-Signature", valid_592486
  var valid_592487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592487 = validateParameter(valid_592487, JString, required = false,
                                 default = nil)
  if valid_592487 != nil:
    section.add "X-Amz-Content-Sha256", valid_592487
  var valid_592488 = header.getOrDefault("X-Amz-Date")
  valid_592488 = validateParameter(valid_592488, JString, required = false,
                                 default = nil)
  if valid_592488 != nil:
    section.add "X-Amz-Date", valid_592488
  var valid_592489 = header.getOrDefault("X-Amz-Credential")
  valid_592489 = validateParameter(valid_592489, JString, required = false,
                                 default = nil)
  if valid_592489 != nil:
    section.add "X-Amz-Credential", valid_592489
  var valid_592490 = header.getOrDefault("X-Amz-Security-Token")
  valid_592490 = validateParameter(valid_592490, JString, required = false,
                                 default = nil)
  if valid_592490 != nil:
    section.add "X-Amz-Security-Token", valid_592490
  var valid_592491 = header.getOrDefault("X-Amz-Algorithm")
  valid_592491 = validateParameter(valid_592491, JString, required = false,
                                 default = nil)
  if valid_592491 != nil:
    section.add "X-Amz-Algorithm", valid_592491
  var valid_592492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592492 = validateParameter(valid_592492, JString, required = false,
                                 default = nil)
  if valid_592492 != nil:
    section.add "X-Amz-SignedHeaders", valid_592492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592494: Call_StartCrawlerSchedule_592482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_592494.validator(path, query, header, formData, body)
  let scheme = call_592494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592494.url(scheme.get, call_592494.host, call_592494.base,
                         call_592494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592494, url, valid)

proc call*(call_592495: Call_StartCrawlerSchedule_592482; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_592496 = newJObject()
  if body != nil:
    body_592496 = body
  result = call_592495.call(nil, nil, nil, nil, body_592496)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_592482(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_592483, base: "/",
    url: url_StartCrawlerSchedule_592484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_592497 = ref object of OpenApiRestCall_590364
proc url_StartExportLabelsTaskRun_592499(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartExportLabelsTaskRun_592498(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592500 = header.getOrDefault("X-Amz-Target")
  valid_592500 = validateParameter(valid_592500, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_592500 != nil:
    section.add "X-Amz-Target", valid_592500
  var valid_592501 = header.getOrDefault("X-Amz-Signature")
  valid_592501 = validateParameter(valid_592501, JString, required = false,
                                 default = nil)
  if valid_592501 != nil:
    section.add "X-Amz-Signature", valid_592501
  var valid_592502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592502 = validateParameter(valid_592502, JString, required = false,
                                 default = nil)
  if valid_592502 != nil:
    section.add "X-Amz-Content-Sha256", valid_592502
  var valid_592503 = header.getOrDefault("X-Amz-Date")
  valid_592503 = validateParameter(valid_592503, JString, required = false,
                                 default = nil)
  if valid_592503 != nil:
    section.add "X-Amz-Date", valid_592503
  var valid_592504 = header.getOrDefault("X-Amz-Credential")
  valid_592504 = validateParameter(valid_592504, JString, required = false,
                                 default = nil)
  if valid_592504 != nil:
    section.add "X-Amz-Credential", valid_592504
  var valid_592505 = header.getOrDefault("X-Amz-Security-Token")
  valid_592505 = validateParameter(valid_592505, JString, required = false,
                                 default = nil)
  if valid_592505 != nil:
    section.add "X-Amz-Security-Token", valid_592505
  var valid_592506 = header.getOrDefault("X-Amz-Algorithm")
  valid_592506 = validateParameter(valid_592506, JString, required = false,
                                 default = nil)
  if valid_592506 != nil:
    section.add "X-Amz-Algorithm", valid_592506
  var valid_592507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592507 = validateParameter(valid_592507, JString, required = false,
                                 default = nil)
  if valid_592507 != nil:
    section.add "X-Amz-SignedHeaders", valid_592507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592509: Call_StartExportLabelsTaskRun_592497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_592509.validator(path, query, header, formData, body)
  let scheme = call_592509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592509.url(scheme.get, call_592509.host, call_592509.base,
                         call_592509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592509, url, valid)

proc call*(call_592510: Call_StartExportLabelsTaskRun_592497; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_592511 = newJObject()
  if body != nil:
    body_592511 = body
  result = call_592510.call(nil, nil, nil, nil, body_592511)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_592497(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_592498, base: "/",
    url: url_StartExportLabelsTaskRun_592499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_592512 = ref object of OpenApiRestCall_590364
proc url_StartImportLabelsTaskRun_592514(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartImportLabelsTaskRun_592513(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592515 = header.getOrDefault("X-Amz-Target")
  valid_592515 = validateParameter(valid_592515, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_592515 != nil:
    section.add "X-Amz-Target", valid_592515
  var valid_592516 = header.getOrDefault("X-Amz-Signature")
  valid_592516 = validateParameter(valid_592516, JString, required = false,
                                 default = nil)
  if valid_592516 != nil:
    section.add "X-Amz-Signature", valid_592516
  var valid_592517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592517 = validateParameter(valid_592517, JString, required = false,
                                 default = nil)
  if valid_592517 != nil:
    section.add "X-Amz-Content-Sha256", valid_592517
  var valid_592518 = header.getOrDefault("X-Amz-Date")
  valid_592518 = validateParameter(valid_592518, JString, required = false,
                                 default = nil)
  if valid_592518 != nil:
    section.add "X-Amz-Date", valid_592518
  var valid_592519 = header.getOrDefault("X-Amz-Credential")
  valid_592519 = validateParameter(valid_592519, JString, required = false,
                                 default = nil)
  if valid_592519 != nil:
    section.add "X-Amz-Credential", valid_592519
  var valid_592520 = header.getOrDefault("X-Amz-Security-Token")
  valid_592520 = validateParameter(valid_592520, JString, required = false,
                                 default = nil)
  if valid_592520 != nil:
    section.add "X-Amz-Security-Token", valid_592520
  var valid_592521 = header.getOrDefault("X-Amz-Algorithm")
  valid_592521 = validateParameter(valid_592521, JString, required = false,
                                 default = nil)
  if valid_592521 != nil:
    section.add "X-Amz-Algorithm", valid_592521
  var valid_592522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592522 = validateParameter(valid_592522, JString, required = false,
                                 default = nil)
  if valid_592522 != nil:
    section.add "X-Amz-SignedHeaders", valid_592522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592524: Call_StartImportLabelsTaskRun_592512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_592524.validator(path, query, header, formData, body)
  let scheme = call_592524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592524.url(scheme.get, call_592524.host, call_592524.base,
                         call_592524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592524, url, valid)

proc call*(call_592525: Call_StartImportLabelsTaskRun_592512; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_592526 = newJObject()
  if body != nil:
    body_592526 = body
  result = call_592525.call(nil, nil, nil, nil, body_592526)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_592512(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_592513, base: "/",
    url: url_StartImportLabelsTaskRun_592514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_592527 = ref object of OpenApiRestCall_590364
proc url_StartJobRun_592529(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartJobRun_592528(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a job run using a job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592530 = header.getOrDefault("X-Amz-Target")
  valid_592530 = validateParameter(valid_592530, JString, required = true,
                                 default = newJString("AWSGlue.StartJobRun"))
  if valid_592530 != nil:
    section.add "X-Amz-Target", valid_592530
  var valid_592531 = header.getOrDefault("X-Amz-Signature")
  valid_592531 = validateParameter(valid_592531, JString, required = false,
                                 default = nil)
  if valid_592531 != nil:
    section.add "X-Amz-Signature", valid_592531
  var valid_592532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592532 = validateParameter(valid_592532, JString, required = false,
                                 default = nil)
  if valid_592532 != nil:
    section.add "X-Amz-Content-Sha256", valid_592532
  var valid_592533 = header.getOrDefault("X-Amz-Date")
  valid_592533 = validateParameter(valid_592533, JString, required = false,
                                 default = nil)
  if valid_592533 != nil:
    section.add "X-Amz-Date", valid_592533
  var valid_592534 = header.getOrDefault("X-Amz-Credential")
  valid_592534 = validateParameter(valid_592534, JString, required = false,
                                 default = nil)
  if valid_592534 != nil:
    section.add "X-Amz-Credential", valid_592534
  var valid_592535 = header.getOrDefault("X-Amz-Security-Token")
  valid_592535 = validateParameter(valid_592535, JString, required = false,
                                 default = nil)
  if valid_592535 != nil:
    section.add "X-Amz-Security-Token", valid_592535
  var valid_592536 = header.getOrDefault("X-Amz-Algorithm")
  valid_592536 = validateParameter(valid_592536, JString, required = false,
                                 default = nil)
  if valid_592536 != nil:
    section.add "X-Amz-Algorithm", valid_592536
  var valid_592537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592537 = validateParameter(valid_592537, JString, required = false,
                                 default = nil)
  if valid_592537 != nil:
    section.add "X-Amz-SignedHeaders", valid_592537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592539: Call_StartJobRun_592527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_592539.validator(path, query, header, formData, body)
  let scheme = call_592539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592539.url(scheme.get, call_592539.host, call_592539.base,
                         call_592539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592539, url, valid)

proc call*(call_592540: Call_StartJobRun_592527; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_592541 = newJObject()
  if body != nil:
    body_592541 = body
  result = call_592540.call(nil, nil, nil, nil, body_592541)

var startJobRun* = Call_StartJobRun_592527(name: "startJobRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StartJobRun",
                                        validator: validate_StartJobRun_592528,
                                        base: "/", url: url_StartJobRun_592529,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_592542 = ref object of OpenApiRestCall_590364
proc url_StartMLEvaluationTaskRun_592544(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMLEvaluationTaskRun_592543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592545 = header.getOrDefault("X-Amz-Target")
  valid_592545 = validateParameter(valid_592545, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_592545 != nil:
    section.add "X-Amz-Target", valid_592545
  var valid_592546 = header.getOrDefault("X-Amz-Signature")
  valid_592546 = validateParameter(valid_592546, JString, required = false,
                                 default = nil)
  if valid_592546 != nil:
    section.add "X-Amz-Signature", valid_592546
  var valid_592547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592547 = validateParameter(valid_592547, JString, required = false,
                                 default = nil)
  if valid_592547 != nil:
    section.add "X-Amz-Content-Sha256", valid_592547
  var valid_592548 = header.getOrDefault("X-Amz-Date")
  valid_592548 = validateParameter(valid_592548, JString, required = false,
                                 default = nil)
  if valid_592548 != nil:
    section.add "X-Amz-Date", valid_592548
  var valid_592549 = header.getOrDefault("X-Amz-Credential")
  valid_592549 = validateParameter(valid_592549, JString, required = false,
                                 default = nil)
  if valid_592549 != nil:
    section.add "X-Amz-Credential", valid_592549
  var valid_592550 = header.getOrDefault("X-Amz-Security-Token")
  valid_592550 = validateParameter(valid_592550, JString, required = false,
                                 default = nil)
  if valid_592550 != nil:
    section.add "X-Amz-Security-Token", valid_592550
  var valid_592551 = header.getOrDefault("X-Amz-Algorithm")
  valid_592551 = validateParameter(valid_592551, JString, required = false,
                                 default = nil)
  if valid_592551 != nil:
    section.add "X-Amz-Algorithm", valid_592551
  var valid_592552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592552 = validateParameter(valid_592552, JString, required = false,
                                 default = nil)
  if valid_592552 != nil:
    section.add "X-Amz-SignedHeaders", valid_592552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592554: Call_StartMLEvaluationTaskRun_592542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_592554.validator(path, query, header, formData, body)
  let scheme = call_592554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592554.url(scheme.get, call_592554.host, call_592554.base,
                         call_592554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592554, url, valid)

proc call*(call_592555: Call_StartMLEvaluationTaskRun_592542; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_592556 = newJObject()
  if body != nil:
    body_592556 = body
  result = call_592555.call(nil, nil, nil, nil, body_592556)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_592542(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_592543, base: "/",
    url: url_StartMLEvaluationTaskRun_592544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_592557 = ref object of OpenApiRestCall_590364
proc url_StartMLLabelingSetGenerationTaskRun_592559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMLLabelingSetGenerationTaskRun_592558(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592560 = header.getOrDefault("X-Amz-Target")
  valid_592560 = validateParameter(valid_592560, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_592560 != nil:
    section.add "X-Amz-Target", valid_592560
  var valid_592561 = header.getOrDefault("X-Amz-Signature")
  valid_592561 = validateParameter(valid_592561, JString, required = false,
                                 default = nil)
  if valid_592561 != nil:
    section.add "X-Amz-Signature", valid_592561
  var valid_592562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592562 = validateParameter(valid_592562, JString, required = false,
                                 default = nil)
  if valid_592562 != nil:
    section.add "X-Amz-Content-Sha256", valid_592562
  var valid_592563 = header.getOrDefault("X-Amz-Date")
  valid_592563 = validateParameter(valid_592563, JString, required = false,
                                 default = nil)
  if valid_592563 != nil:
    section.add "X-Amz-Date", valid_592563
  var valid_592564 = header.getOrDefault("X-Amz-Credential")
  valid_592564 = validateParameter(valid_592564, JString, required = false,
                                 default = nil)
  if valid_592564 != nil:
    section.add "X-Amz-Credential", valid_592564
  var valid_592565 = header.getOrDefault("X-Amz-Security-Token")
  valid_592565 = validateParameter(valid_592565, JString, required = false,
                                 default = nil)
  if valid_592565 != nil:
    section.add "X-Amz-Security-Token", valid_592565
  var valid_592566 = header.getOrDefault("X-Amz-Algorithm")
  valid_592566 = validateParameter(valid_592566, JString, required = false,
                                 default = nil)
  if valid_592566 != nil:
    section.add "X-Amz-Algorithm", valid_592566
  var valid_592567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592567 = validateParameter(valid_592567, JString, required = false,
                                 default = nil)
  if valid_592567 != nil:
    section.add "X-Amz-SignedHeaders", valid_592567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592569: Call_StartMLLabelingSetGenerationTaskRun_592557;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_592569.validator(path, query, header, formData, body)
  let scheme = call_592569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592569.url(scheme.get, call_592569.host, call_592569.base,
                         call_592569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592569, url, valid)

proc call*(call_592570: Call_StartMLLabelingSetGenerationTaskRun_592557;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_592571 = newJObject()
  if body != nil:
    body_592571 = body
  result = call_592570.call(nil, nil, nil, nil, body_592571)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_592557(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_592558, base: "/",
    url: url_StartMLLabelingSetGenerationTaskRun_592559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_592572 = ref object of OpenApiRestCall_590364
proc url_StartTrigger_592574(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartTrigger_592573(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592575 = header.getOrDefault("X-Amz-Target")
  valid_592575 = validateParameter(valid_592575, JString, required = true,
                                 default = newJString("AWSGlue.StartTrigger"))
  if valid_592575 != nil:
    section.add "X-Amz-Target", valid_592575
  var valid_592576 = header.getOrDefault("X-Amz-Signature")
  valid_592576 = validateParameter(valid_592576, JString, required = false,
                                 default = nil)
  if valid_592576 != nil:
    section.add "X-Amz-Signature", valid_592576
  var valid_592577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592577 = validateParameter(valid_592577, JString, required = false,
                                 default = nil)
  if valid_592577 != nil:
    section.add "X-Amz-Content-Sha256", valid_592577
  var valid_592578 = header.getOrDefault("X-Amz-Date")
  valid_592578 = validateParameter(valid_592578, JString, required = false,
                                 default = nil)
  if valid_592578 != nil:
    section.add "X-Amz-Date", valid_592578
  var valid_592579 = header.getOrDefault("X-Amz-Credential")
  valid_592579 = validateParameter(valid_592579, JString, required = false,
                                 default = nil)
  if valid_592579 != nil:
    section.add "X-Amz-Credential", valid_592579
  var valid_592580 = header.getOrDefault("X-Amz-Security-Token")
  valid_592580 = validateParameter(valid_592580, JString, required = false,
                                 default = nil)
  if valid_592580 != nil:
    section.add "X-Amz-Security-Token", valid_592580
  var valid_592581 = header.getOrDefault("X-Amz-Algorithm")
  valid_592581 = validateParameter(valid_592581, JString, required = false,
                                 default = nil)
  if valid_592581 != nil:
    section.add "X-Amz-Algorithm", valid_592581
  var valid_592582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592582 = validateParameter(valid_592582, JString, required = false,
                                 default = nil)
  if valid_592582 != nil:
    section.add "X-Amz-SignedHeaders", valid_592582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592584: Call_StartTrigger_592572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_592584.validator(path, query, header, formData, body)
  let scheme = call_592584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592584.url(scheme.get, call_592584.host, call_592584.base,
                         call_592584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592584, url, valid)

proc call*(call_592585: Call_StartTrigger_592572; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_592586 = newJObject()
  if body != nil:
    body_592586 = body
  result = call_592585.call(nil, nil, nil, nil, body_592586)

var startTrigger* = Call_StartTrigger_592572(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_592573, base: "/", url: url_StartTrigger_592574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_592587 = ref object of OpenApiRestCall_590364
proc url_StartWorkflowRun_592589(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartWorkflowRun_592588(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Starts a new run of the specified workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592590 = header.getOrDefault("X-Amz-Target")
  valid_592590 = validateParameter(valid_592590, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_592590 != nil:
    section.add "X-Amz-Target", valid_592590
  var valid_592591 = header.getOrDefault("X-Amz-Signature")
  valid_592591 = validateParameter(valid_592591, JString, required = false,
                                 default = nil)
  if valid_592591 != nil:
    section.add "X-Amz-Signature", valid_592591
  var valid_592592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592592 = validateParameter(valid_592592, JString, required = false,
                                 default = nil)
  if valid_592592 != nil:
    section.add "X-Amz-Content-Sha256", valid_592592
  var valid_592593 = header.getOrDefault("X-Amz-Date")
  valid_592593 = validateParameter(valid_592593, JString, required = false,
                                 default = nil)
  if valid_592593 != nil:
    section.add "X-Amz-Date", valid_592593
  var valid_592594 = header.getOrDefault("X-Amz-Credential")
  valid_592594 = validateParameter(valid_592594, JString, required = false,
                                 default = nil)
  if valid_592594 != nil:
    section.add "X-Amz-Credential", valid_592594
  var valid_592595 = header.getOrDefault("X-Amz-Security-Token")
  valid_592595 = validateParameter(valid_592595, JString, required = false,
                                 default = nil)
  if valid_592595 != nil:
    section.add "X-Amz-Security-Token", valid_592595
  var valid_592596 = header.getOrDefault("X-Amz-Algorithm")
  valid_592596 = validateParameter(valid_592596, JString, required = false,
                                 default = nil)
  if valid_592596 != nil:
    section.add "X-Amz-Algorithm", valid_592596
  var valid_592597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592597 = validateParameter(valid_592597, JString, required = false,
                                 default = nil)
  if valid_592597 != nil:
    section.add "X-Amz-SignedHeaders", valid_592597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592599: Call_StartWorkflowRun_592587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_592599.validator(path, query, header, formData, body)
  let scheme = call_592599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592599.url(scheme.get, call_592599.host, call_592599.base,
                         call_592599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592599, url, valid)

proc call*(call_592600: Call_StartWorkflowRun_592587; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_592601 = newJObject()
  if body != nil:
    body_592601 = body
  result = call_592600.call(nil, nil, nil, nil, body_592601)

var startWorkflowRun* = Call_StartWorkflowRun_592587(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_592588, base: "/",
    url: url_StartWorkflowRun_592589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_592602 = ref object of OpenApiRestCall_590364
proc url_StopCrawler_592604(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCrawler_592603(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## If the specified crawler is running, stops the crawl.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592605 = header.getOrDefault("X-Amz-Target")
  valid_592605 = validateParameter(valid_592605, JString, required = true,
                                 default = newJString("AWSGlue.StopCrawler"))
  if valid_592605 != nil:
    section.add "X-Amz-Target", valid_592605
  var valid_592606 = header.getOrDefault("X-Amz-Signature")
  valid_592606 = validateParameter(valid_592606, JString, required = false,
                                 default = nil)
  if valid_592606 != nil:
    section.add "X-Amz-Signature", valid_592606
  var valid_592607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592607 = validateParameter(valid_592607, JString, required = false,
                                 default = nil)
  if valid_592607 != nil:
    section.add "X-Amz-Content-Sha256", valid_592607
  var valid_592608 = header.getOrDefault("X-Amz-Date")
  valid_592608 = validateParameter(valid_592608, JString, required = false,
                                 default = nil)
  if valid_592608 != nil:
    section.add "X-Amz-Date", valid_592608
  var valid_592609 = header.getOrDefault("X-Amz-Credential")
  valid_592609 = validateParameter(valid_592609, JString, required = false,
                                 default = nil)
  if valid_592609 != nil:
    section.add "X-Amz-Credential", valid_592609
  var valid_592610 = header.getOrDefault("X-Amz-Security-Token")
  valid_592610 = validateParameter(valid_592610, JString, required = false,
                                 default = nil)
  if valid_592610 != nil:
    section.add "X-Amz-Security-Token", valid_592610
  var valid_592611 = header.getOrDefault("X-Amz-Algorithm")
  valid_592611 = validateParameter(valid_592611, JString, required = false,
                                 default = nil)
  if valid_592611 != nil:
    section.add "X-Amz-Algorithm", valid_592611
  var valid_592612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592612 = validateParameter(valid_592612, JString, required = false,
                                 default = nil)
  if valid_592612 != nil:
    section.add "X-Amz-SignedHeaders", valid_592612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592614: Call_StopCrawler_592602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_592614.validator(path, query, header, formData, body)
  let scheme = call_592614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592614.url(scheme.get, call_592614.host, call_592614.base,
                         call_592614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592614, url, valid)

proc call*(call_592615: Call_StopCrawler_592602; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_592616 = newJObject()
  if body != nil:
    body_592616 = body
  result = call_592615.call(nil, nil, nil, nil, body_592616)

var stopCrawler* = Call_StopCrawler_592602(name: "stopCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopCrawler",
                                        validator: validate_StopCrawler_592603,
                                        base: "/", url: url_StopCrawler_592604,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_592617 = ref object of OpenApiRestCall_590364
proc url_StopCrawlerSchedule_592619(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCrawlerSchedule_592618(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592620 = header.getOrDefault("X-Amz-Target")
  valid_592620 = validateParameter(valid_592620, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_592620 != nil:
    section.add "X-Amz-Target", valid_592620
  var valid_592621 = header.getOrDefault("X-Amz-Signature")
  valid_592621 = validateParameter(valid_592621, JString, required = false,
                                 default = nil)
  if valid_592621 != nil:
    section.add "X-Amz-Signature", valid_592621
  var valid_592622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592622 = validateParameter(valid_592622, JString, required = false,
                                 default = nil)
  if valid_592622 != nil:
    section.add "X-Amz-Content-Sha256", valid_592622
  var valid_592623 = header.getOrDefault("X-Amz-Date")
  valid_592623 = validateParameter(valid_592623, JString, required = false,
                                 default = nil)
  if valid_592623 != nil:
    section.add "X-Amz-Date", valid_592623
  var valid_592624 = header.getOrDefault("X-Amz-Credential")
  valid_592624 = validateParameter(valid_592624, JString, required = false,
                                 default = nil)
  if valid_592624 != nil:
    section.add "X-Amz-Credential", valid_592624
  var valid_592625 = header.getOrDefault("X-Amz-Security-Token")
  valid_592625 = validateParameter(valid_592625, JString, required = false,
                                 default = nil)
  if valid_592625 != nil:
    section.add "X-Amz-Security-Token", valid_592625
  var valid_592626 = header.getOrDefault("X-Amz-Algorithm")
  valid_592626 = validateParameter(valid_592626, JString, required = false,
                                 default = nil)
  if valid_592626 != nil:
    section.add "X-Amz-Algorithm", valid_592626
  var valid_592627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592627 = validateParameter(valid_592627, JString, required = false,
                                 default = nil)
  if valid_592627 != nil:
    section.add "X-Amz-SignedHeaders", valid_592627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592629: Call_StopCrawlerSchedule_592617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_592629.validator(path, query, header, formData, body)
  let scheme = call_592629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592629.url(scheme.get, call_592629.host, call_592629.base,
                         call_592629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592629, url, valid)

proc call*(call_592630: Call_StopCrawlerSchedule_592617; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_592631 = newJObject()
  if body != nil:
    body_592631 = body
  result = call_592630.call(nil, nil, nil, nil, body_592631)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_592617(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_592618, base: "/",
    url: url_StopCrawlerSchedule_592619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_592632 = ref object of OpenApiRestCall_590364
proc url_StopTrigger_592634(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTrigger_592633(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a specified trigger.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592635 = header.getOrDefault("X-Amz-Target")
  valid_592635 = validateParameter(valid_592635, JString, required = true,
                                 default = newJString("AWSGlue.StopTrigger"))
  if valid_592635 != nil:
    section.add "X-Amz-Target", valid_592635
  var valid_592636 = header.getOrDefault("X-Amz-Signature")
  valid_592636 = validateParameter(valid_592636, JString, required = false,
                                 default = nil)
  if valid_592636 != nil:
    section.add "X-Amz-Signature", valid_592636
  var valid_592637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592637 = validateParameter(valid_592637, JString, required = false,
                                 default = nil)
  if valid_592637 != nil:
    section.add "X-Amz-Content-Sha256", valid_592637
  var valid_592638 = header.getOrDefault("X-Amz-Date")
  valid_592638 = validateParameter(valid_592638, JString, required = false,
                                 default = nil)
  if valid_592638 != nil:
    section.add "X-Amz-Date", valid_592638
  var valid_592639 = header.getOrDefault("X-Amz-Credential")
  valid_592639 = validateParameter(valid_592639, JString, required = false,
                                 default = nil)
  if valid_592639 != nil:
    section.add "X-Amz-Credential", valid_592639
  var valid_592640 = header.getOrDefault("X-Amz-Security-Token")
  valid_592640 = validateParameter(valid_592640, JString, required = false,
                                 default = nil)
  if valid_592640 != nil:
    section.add "X-Amz-Security-Token", valid_592640
  var valid_592641 = header.getOrDefault("X-Amz-Algorithm")
  valid_592641 = validateParameter(valid_592641, JString, required = false,
                                 default = nil)
  if valid_592641 != nil:
    section.add "X-Amz-Algorithm", valid_592641
  var valid_592642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592642 = validateParameter(valid_592642, JString, required = false,
                                 default = nil)
  if valid_592642 != nil:
    section.add "X-Amz-SignedHeaders", valid_592642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592644: Call_StopTrigger_592632; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_592644.validator(path, query, header, formData, body)
  let scheme = call_592644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592644.url(scheme.get, call_592644.host, call_592644.base,
                         call_592644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592644, url, valid)

proc call*(call_592645: Call_StopTrigger_592632; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_592646 = newJObject()
  if body != nil:
    body_592646 = body
  result = call_592645.call(nil, nil, nil, nil, body_592646)

var stopTrigger* = Call_StopTrigger_592632(name: "stopTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopTrigger",
                                        validator: validate_StopTrigger_592633,
                                        base: "/", url: url_StopTrigger_592634,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_592647 = ref object of OpenApiRestCall_590364
proc url_TagResource_592649(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_592648(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592650 = header.getOrDefault("X-Amz-Target")
  valid_592650 = validateParameter(valid_592650, JString, required = true,
                                 default = newJString("AWSGlue.TagResource"))
  if valid_592650 != nil:
    section.add "X-Amz-Target", valid_592650
  var valid_592651 = header.getOrDefault("X-Amz-Signature")
  valid_592651 = validateParameter(valid_592651, JString, required = false,
                                 default = nil)
  if valid_592651 != nil:
    section.add "X-Amz-Signature", valid_592651
  var valid_592652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592652 = validateParameter(valid_592652, JString, required = false,
                                 default = nil)
  if valid_592652 != nil:
    section.add "X-Amz-Content-Sha256", valid_592652
  var valid_592653 = header.getOrDefault("X-Amz-Date")
  valid_592653 = validateParameter(valid_592653, JString, required = false,
                                 default = nil)
  if valid_592653 != nil:
    section.add "X-Amz-Date", valid_592653
  var valid_592654 = header.getOrDefault("X-Amz-Credential")
  valid_592654 = validateParameter(valid_592654, JString, required = false,
                                 default = nil)
  if valid_592654 != nil:
    section.add "X-Amz-Credential", valid_592654
  var valid_592655 = header.getOrDefault("X-Amz-Security-Token")
  valid_592655 = validateParameter(valid_592655, JString, required = false,
                                 default = nil)
  if valid_592655 != nil:
    section.add "X-Amz-Security-Token", valid_592655
  var valid_592656 = header.getOrDefault("X-Amz-Algorithm")
  valid_592656 = validateParameter(valid_592656, JString, required = false,
                                 default = nil)
  if valid_592656 != nil:
    section.add "X-Amz-Algorithm", valid_592656
  var valid_592657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592657 = validateParameter(valid_592657, JString, required = false,
                                 default = nil)
  if valid_592657 != nil:
    section.add "X-Amz-SignedHeaders", valid_592657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592659: Call_TagResource_592647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_592659.validator(path, query, header, formData, body)
  let scheme = call_592659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592659.url(scheme.get, call_592659.host, call_592659.base,
                         call_592659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592659, url, valid)

proc call*(call_592660: Call_TagResource_592647; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_592661 = newJObject()
  if body != nil:
    body_592661 = body
  result = call_592660.call(nil, nil, nil, nil, body_592661)

var tagResource* = Call_TagResource_592647(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.TagResource",
                                        validator: validate_TagResource_592648,
                                        base: "/", url: url_TagResource_592649,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_592662 = ref object of OpenApiRestCall_590364
proc url_UntagResource_592664(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_592663(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592665 = header.getOrDefault("X-Amz-Target")
  valid_592665 = validateParameter(valid_592665, JString, required = true,
                                 default = newJString("AWSGlue.UntagResource"))
  if valid_592665 != nil:
    section.add "X-Amz-Target", valid_592665
  var valid_592666 = header.getOrDefault("X-Amz-Signature")
  valid_592666 = validateParameter(valid_592666, JString, required = false,
                                 default = nil)
  if valid_592666 != nil:
    section.add "X-Amz-Signature", valid_592666
  var valid_592667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592667 = validateParameter(valid_592667, JString, required = false,
                                 default = nil)
  if valid_592667 != nil:
    section.add "X-Amz-Content-Sha256", valid_592667
  var valid_592668 = header.getOrDefault("X-Amz-Date")
  valid_592668 = validateParameter(valid_592668, JString, required = false,
                                 default = nil)
  if valid_592668 != nil:
    section.add "X-Amz-Date", valid_592668
  var valid_592669 = header.getOrDefault("X-Amz-Credential")
  valid_592669 = validateParameter(valid_592669, JString, required = false,
                                 default = nil)
  if valid_592669 != nil:
    section.add "X-Amz-Credential", valid_592669
  var valid_592670 = header.getOrDefault("X-Amz-Security-Token")
  valid_592670 = validateParameter(valid_592670, JString, required = false,
                                 default = nil)
  if valid_592670 != nil:
    section.add "X-Amz-Security-Token", valid_592670
  var valid_592671 = header.getOrDefault("X-Amz-Algorithm")
  valid_592671 = validateParameter(valid_592671, JString, required = false,
                                 default = nil)
  if valid_592671 != nil:
    section.add "X-Amz-Algorithm", valid_592671
  var valid_592672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592672 = validateParameter(valid_592672, JString, required = false,
                                 default = nil)
  if valid_592672 != nil:
    section.add "X-Amz-SignedHeaders", valid_592672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592674: Call_UntagResource_592662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_592674.validator(path, query, header, formData, body)
  let scheme = call_592674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592674.url(scheme.get, call_592674.host, call_592674.base,
                         call_592674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592674, url, valid)

proc call*(call_592675: Call_UntagResource_592662; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_592676 = newJObject()
  if body != nil:
    body_592676 = body
  result = call_592675.call(nil, nil, nil, nil, body_592676)

var untagResource* = Call_UntagResource_592662(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_592663, base: "/", url: url_UntagResource_592664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_592677 = ref object of OpenApiRestCall_590364
proc url_UpdateClassifier_592679(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateClassifier_592678(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592680 = header.getOrDefault("X-Amz-Target")
  valid_592680 = validateParameter(valid_592680, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_592680 != nil:
    section.add "X-Amz-Target", valid_592680
  var valid_592681 = header.getOrDefault("X-Amz-Signature")
  valid_592681 = validateParameter(valid_592681, JString, required = false,
                                 default = nil)
  if valid_592681 != nil:
    section.add "X-Amz-Signature", valid_592681
  var valid_592682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592682 = validateParameter(valid_592682, JString, required = false,
                                 default = nil)
  if valid_592682 != nil:
    section.add "X-Amz-Content-Sha256", valid_592682
  var valid_592683 = header.getOrDefault("X-Amz-Date")
  valid_592683 = validateParameter(valid_592683, JString, required = false,
                                 default = nil)
  if valid_592683 != nil:
    section.add "X-Amz-Date", valid_592683
  var valid_592684 = header.getOrDefault("X-Amz-Credential")
  valid_592684 = validateParameter(valid_592684, JString, required = false,
                                 default = nil)
  if valid_592684 != nil:
    section.add "X-Amz-Credential", valid_592684
  var valid_592685 = header.getOrDefault("X-Amz-Security-Token")
  valid_592685 = validateParameter(valid_592685, JString, required = false,
                                 default = nil)
  if valid_592685 != nil:
    section.add "X-Amz-Security-Token", valid_592685
  var valid_592686 = header.getOrDefault("X-Amz-Algorithm")
  valid_592686 = validateParameter(valid_592686, JString, required = false,
                                 default = nil)
  if valid_592686 != nil:
    section.add "X-Amz-Algorithm", valid_592686
  var valid_592687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592687 = validateParameter(valid_592687, JString, required = false,
                                 default = nil)
  if valid_592687 != nil:
    section.add "X-Amz-SignedHeaders", valid_592687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592689: Call_UpdateClassifier_592677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_592689.validator(path, query, header, formData, body)
  let scheme = call_592689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592689.url(scheme.get, call_592689.host, call_592689.base,
                         call_592689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592689, url, valid)

proc call*(call_592690: Call_UpdateClassifier_592677; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_592691 = newJObject()
  if body != nil:
    body_592691 = body
  result = call_592690.call(nil, nil, nil, nil, body_592691)

var updateClassifier* = Call_UpdateClassifier_592677(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_592678, base: "/",
    url: url_UpdateClassifier_592679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_592692 = ref object of OpenApiRestCall_590364
proc url_UpdateConnection_592694(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateConnection_592693(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a connection definition in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592695 = header.getOrDefault("X-Amz-Target")
  valid_592695 = validateParameter(valid_592695, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_592695 != nil:
    section.add "X-Amz-Target", valid_592695
  var valid_592696 = header.getOrDefault("X-Amz-Signature")
  valid_592696 = validateParameter(valid_592696, JString, required = false,
                                 default = nil)
  if valid_592696 != nil:
    section.add "X-Amz-Signature", valid_592696
  var valid_592697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592697 = validateParameter(valid_592697, JString, required = false,
                                 default = nil)
  if valid_592697 != nil:
    section.add "X-Amz-Content-Sha256", valid_592697
  var valid_592698 = header.getOrDefault("X-Amz-Date")
  valid_592698 = validateParameter(valid_592698, JString, required = false,
                                 default = nil)
  if valid_592698 != nil:
    section.add "X-Amz-Date", valid_592698
  var valid_592699 = header.getOrDefault("X-Amz-Credential")
  valid_592699 = validateParameter(valid_592699, JString, required = false,
                                 default = nil)
  if valid_592699 != nil:
    section.add "X-Amz-Credential", valid_592699
  var valid_592700 = header.getOrDefault("X-Amz-Security-Token")
  valid_592700 = validateParameter(valid_592700, JString, required = false,
                                 default = nil)
  if valid_592700 != nil:
    section.add "X-Amz-Security-Token", valid_592700
  var valid_592701 = header.getOrDefault("X-Amz-Algorithm")
  valid_592701 = validateParameter(valid_592701, JString, required = false,
                                 default = nil)
  if valid_592701 != nil:
    section.add "X-Amz-Algorithm", valid_592701
  var valid_592702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592702 = validateParameter(valid_592702, JString, required = false,
                                 default = nil)
  if valid_592702 != nil:
    section.add "X-Amz-SignedHeaders", valid_592702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592704: Call_UpdateConnection_592692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_592704.validator(path, query, header, formData, body)
  let scheme = call_592704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592704.url(scheme.get, call_592704.host, call_592704.base,
                         call_592704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592704, url, valid)

proc call*(call_592705: Call_UpdateConnection_592692; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_592706 = newJObject()
  if body != nil:
    body_592706 = body
  result = call_592705.call(nil, nil, nil, nil, body_592706)

var updateConnection* = Call_UpdateConnection_592692(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_592693, base: "/",
    url: url_UpdateConnection_592694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_592707 = ref object of OpenApiRestCall_590364
proc url_UpdateCrawler_592709(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCrawler_592708(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592710 = header.getOrDefault("X-Amz-Target")
  valid_592710 = validateParameter(valid_592710, JString, required = true,
                                 default = newJString("AWSGlue.UpdateCrawler"))
  if valid_592710 != nil:
    section.add "X-Amz-Target", valid_592710
  var valid_592711 = header.getOrDefault("X-Amz-Signature")
  valid_592711 = validateParameter(valid_592711, JString, required = false,
                                 default = nil)
  if valid_592711 != nil:
    section.add "X-Amz-Signature", valid_592711
  var valid_592712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592712 = validateParameter(valid_592712, JString, required = false,
                                 default = nil)
  if valid_592712 != nil:
    section.add "X-Amz-Content-Sha256", valid_592712
  var valid_592713 = header.getOrDefault("X-Amz-Date")
  valid_592713 = validateParameter(valid_592713, JString, required = false,
                                 default = nil)
  if valid_592713 != nil:
    section.add "X-Amz-Date", valid_592713
  var valid_592714 = header.getOrDefault("X-Amz-Credential")
  valid_592714 = validateParameter(valid_592714, JString, required = false,
                                 default = nil)
  if valid_592714 != nil:
    section.add "X-Amz-Credential", valid_592714
  var valid_592715 = header.getOrDefault("X-Amz-Security-Token")
  valid_592715 = validateParameter(valid_592715, JString, required = false,
                                 default = nil)
  if valid_592715 != nil:
    section.add "X-Amz-Security-Token", valid_592715
  var valid_592716 = header.getOrDefault("X-Amz-Algorithm")
  valid_592716 = validateParameter(valid_592716, JString, required = false,
                                 default = nil)
  if valid_592716 != nil:
    section.add "X-Amz-Algorithm", valid_592716
  var valid_592717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592717 = validateParameter(valid_592717, JString, required = false,
                                 default = nil)
  if valid_592717 != nil:
    section.add "X-Amz-SignedHeaders", valid_592717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592719: Call_UpdateCrawler_592707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_592719.validator(path, query, header, formData, body)
  let scheme = call_592719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592719.url(scheme.get, call_592719.host, call_592719.base,
                         call_592719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592719, url, valid)

proc call*(call_592720: Call_UpdateCrawler_592707; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_592721 = newJObject()
  if body != nil:
    body_592721 = body
  result = call_592720.call(nil, nil, nil, nil, body_592721)

var updateCrawler* = Call_UpdateCrawler_592707(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_592708, base: "/", url: url_UpdateCrawler_592709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_592722 = ref object of OpenApiRestCall_590364
proc url_UpdateCrawlerSchedule_592724(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCrawlerSchedule_592723(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592725 = header.getOrDefault("X-Amz-Target")
  valid_592725 = validateParameter(valid_592725, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_592725 != nil:
    section.add "X-Amz-Target", valid_592725
  var valid_592726 = header.getOrDefault("X-Amz-Signature")
  valid_592726 = validateParameter(valid_592726, JString, required = false,
                                 default = nil)
  if valid_592726 != nil:
    section.add "X-Amz-Signature", valid_592726
  var valid_592727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592727 = validateParameter(valid_592727, JString, required = false,
                                 default = nil)
  if valid_592727 != nil:
    section.add "X-Amz-Content-Sha256", valid_592727
  var valid_592728 = header.getOrDefault("X-Amz-Date")
  valid_592728 = validateParameter(valid_592728, JString, required = false,
                                 default = nil)
  if valid_592728 != nil:
    section.add "X-Amz-Date", valid_592728
  var valid_592729 = header.getOrDefault("X-Amz-Credential")
  valid_592729 = validateParameter(valid_592729, JString, required = false,
                                 default = nil)
  if valid_592729 != nil:
    section.add "X-Amz-Credential", valid_592729
  var valid_592730 = header.getOrDefault("X-Amz-Security-Token")
  valid_592730 = validateParameter(valid_592730, JString, required = false,
                                 default = nil)
  if valid_592730 != nil:
    section.add "X-Amz-Security-Token", valid_592730
  var valid_592731 = header.getOrDefault("X-Amz-Algorithm")
  valid_592731 = validateParameter(valid_592731, JString, required = false,
                                 default = nil)
  if valid_592731 != nil:
    section.add "X-Amz-Algorithm", valid_592731
  var valid_592732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592732 = validateParameter(valid_592732, JString, required = false,
                                 default = nil)
  if valid_592732 != nil:
    section.add "X-Amz-SignedHeaders", valid_592732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592734: Call_UpdateCrawlerSchedule_592722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_592734.validator(path, query, header, formData, body)
  let scheme = call_592734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592734.url(scheme.get, call_592734.host, call_592734.base,
                         call_592734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592734, url, valid)

proc call*(call_592735: Call_UpdateCrawlerSchedule_592722; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_592736 = newJObject()
  if body != nil:
    body_592736 = body
  result = call_592735.call(nil, nil, nil, nil, body_592736)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_592722(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_592723, base: "/",
    url: url_UpdateCrawlerSchedule_592724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_592737 = ref object of OpenApiRestCall_590364
proc url_UpdateDatabase_592739(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDatabase_592738(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592740 = header.getOrDefault("X-Amz-Target")
  valid_592740 = validateParameter(valid_592740, JString, required = true,
                                 default = newJString("AWSGlue.UpdateDatabase"))
  if valid_592740 != nil:
    section.add "X-Amz-Target", valid_592740
  var valid_592741 = header.getOrDefault("X-Amz-Signature")
  valid_592741 = validateParameter(valid_592741, JString, required = false,
                                 default = nil)
  if valid_592741 != nil:
    section.add "X-Amz-Signature", valid_592741
  var valid_592742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592742 = validateParameter(valid_592742, JString, required = false,
                                 default = nil)
  if valid_592742 != nil:
    section.add "X-Amz-Content-Sha256", valid_592742
  var valid_592743 = header.getOrDefault("X-Amz-Date")
  valid_592743 = validateParameter(valid_592743, JString, required = false,
                                 default = nil)
  if valid_592743 != nil:
    section.add "X-Amz-Date", valid_592743
  var valid_592744 = header.getOrDefault("X-Amz-Credential")
  valid_592744 = validateParameter(valid_592744, JString, required = false,
                                 default = nil)
  if valid_592744 != nil:
    section.add "X-Amz-Credential", valid_592744
  var valid_592745 = header.getOrDefault("X-Amz-Security-Token")
  valid_592745 = validateParameter(valid_592745, JString, required = false,
                                 default = nil)
  if valid_592745 != nil:
    section.add "X-Amz-Security-Token", valid_592745
  var valid_592746 = header.getOrDefault("X-Amz-Algorithm")
  valid_592746 = validateParameter(valid_592746, JString, required = false,
                                 default = nil)
  if valid_592746 != nil:
    section.add "X-Amz-Algorithm", valid_592746
  var valid_592747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592747 = validateParameter(valid_592747, JString, required = false,
                                 default = nil)
  if valid_592747 != nil:
    section.add "X-Amz-SignedHeaders", valid_592747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592749: Call_UpdateDatabase_592737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_592749.validator(path, query, header, formData, body)
  let scheme = call_592749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592749.url(scheme.get, call_592749.host, call_592749.base,
                         call_592749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592749, url, valid)

proc call*(call_592750: Call_UpdateDatabase_592737; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_592751 = newJObject()
  if body != nil:
    body_592751 = body
  result = call_592750.call(nil, nil, nil, nil, body_592751)

var updateDatabase* = Call_UpdateDatabase_592737(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_592738, base: "/", url: url_UpdateDatabase_592739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_592752 = ref object of OpenApiRestCall_590364
proc url_UpdateDevEndpoint_592754(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevEndpoint_592753(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates a specified development endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592755 = header.getOrDefault("X-Amz-Target")
  valid_592755 = validateParameter(valid_592755, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_592755 != nil:
    section.add "X-Amz-Target", valid_592755
  var valid_592756 = header.getOrDefault("X-Amz-Signature")
  valid_592756 = validateParameter(valid_592756, JString, required = false,
                                 default = nil)
  if valid_592756 != nil:
    section.add "X-Amz-Signature", valid_592756
  var valid_592757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592757 = validateParameter(valid_592757, JString, required = false,
                                 default = nil)
  if valid_592757 != nil:
    section.add "X-Amz-Content-Sha256", valid_592757
  var valid_592758 = header.getOrDefault("X-Amz-Date")
  valid_592758 = validateParameter(valid_592758, JString, required = false,
                                 default = nil)
  if valid_592758 != nil:
    section.add "X-Amz-Date", valid_592758
  var valid_592759 = header.getOrDefault("X-Amz-Credential")
  valid_592759 = validateParameter(valid_592759, JString, required = false,
                                 default = nil)
  if valid_592759 != nil:
    section.add "X-Amz-Credential", valid_592759
  var valid_592760 = header.getOrDefault("X-Amz-Security-Token")
  valid_592760 = validateParameter(valid_592760, JString, required = false,
                                 default = nil)
  if valid_592760 != nil:
    section.add "X-Amz-Security-Token", valid_592760
  var valid_592761 = header.getOrDefault("X-Amz-Algorithm")
  valid_592761 = validateParameter(valid_592761, JString, required = false,
                                 default = nil)
  if valid_592761 != nil:
    section.add "X-Amz-Algorithm", valid_592761
  var valid_592762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592762 = validateParameter(valid_592762, JString, required = false,
                                 default = nil)
  if valid_592762 != nil:
    section.add "X-Amz-SignedHeaders", valid_592762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592764: Call_UpdateDevEndpoint_592752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_592764.validator(path, query, header, formData, body)
  let scheme = call_592764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592764.url(scheme.get, call_592764.host, call_592764.base,
                         call_592764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592764, url, valid)

proc call*(call_592765: Call_UpdateDevEndpoint_592752; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_592766 = newJObject()
  if body != nil:
    body_592766 = body
  result = call_592765.call(nil, nil, nil, nil, body_592766)

var updateDevEndpoint* = Call_UpdateDevEndpoint_592752(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_592753, base: "/",
    url: url_UpdateDevEndpoint_592754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_592767 = ref object of OpenApiRestCall_590364
proc url_UpdateJob_592769(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateJob_592768(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592770 = header.getOrDefault("X-Amz-Target")
  valid_592770 = validateParameter(valid_592770, JString, required = true,
                                 default = newJString("AWSGlue.UpdateJob"))
  if valid_592770 != nil:
    section.add "X-Amz-Target", valid_592770
  var valid_592771 = header.getOrDefault("X-Amz-Signature")
  valid_592771 = validateParameter(valid_592771, JString, required = false,
                                 default = nil)
  if valid_592771 != nil:
    section.add "X-Amz-Signature", valid_592771
  var valid_592772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592772 = validateParameter(valid_592772, JString, required = false,
                                 default = nil)
  if valid_592772 != nil:
    section.add "X-Amz-Content-Sha256", valid_592772
  var valid_592773 = header.getOrDefault("X-Amz-Date")
  valid_592773 = validateParameter(valid_592773, JString, required = false,
                                 default = nil)
  if valid_592773 != nil:
    section.add "X-Amz-Date", valid_592773
  var valid_592774 = header.getOrDefault("X-Amz-Credential")
  valid_592774 = validateParameter(valid_592774, JString, required = false,
                                 default = nil)
  if valid_592774 != nil:
    section.add "X-Amz-Credential", valid_592774
  var valid_592775 = header.getOrDefault("X-Amz-Security-Token")
  valid_592775 = validateParameter(valid_592775, JString, required = false,
                                 default = nil)
  if valid_592775 != nil:
    section.add "X-Amz-Security-Token", valid_592775
  var valid_592776 = header.getOrDefault("X-Amz-Algorithm")
  valid_592776 = validateParameter(valid_592776, JString, required = false,
                                 default = nil)
  if valid_592776 != nil:
    section.add "X-Amz-Algorithm", valid_592776
  var valid_592777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592777 = validateParameter(valid_592777, JString, required = false,
                                 default = nil)
  if valid_592777 != nil:
    section.add "X-Amz-SignedHeaders", valid_592777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592779: Call_UpdateJob_592767; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_592779.validator(path, query, header, formData, body)
  let scheme = call_592779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592779.url(scheme.get, call_592779.host, call_592779.base,
                         call_592779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592779, url, valid)

proc call*(call_592780: Call_UpdateJob_592767; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_592781 = newJObject()
  if body != nil:
    body_592781 = body
  result = call_592780.call(nil, nil, nil, nil, body_592781)

var updateJob* = Call_UpdateJob_592767(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                    validator: validate_UpdateJob_592768,
                                    base: "/", url: url_UpdateJob_592769,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_592782 = ref object of OpenApiRestCall_590364
proc url_UpdateMLTransform_592784(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMLTransform_592783(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592785 = header.getOrDefault("X-Amz-Target")
  valid_592785 = validateParameter(valid_592785, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_592785 != nil:
    section.add "X-Amz-Target", valid_592785
  var valid_592786 = header.getOrDefault("X-Amz-Signature")
  valid_592786 = validateParameter(valid_592786, JString, required = false,
                                 default = nil)
  if valid_592786 != nil:
    section.add "X-Amz-Signature", valid_592786
  var valid_592787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592787 = validateParameter(valid_592787, JString, required = false,
                                 default = nil)
  if valid_592787 != nil:
    section.add "X-Amz-Content-Sha256", valid_592787
  var valid_592788 = header.getOrDefault("X-Amz-Date")
  valid_592788 = validateParameter(valid_592788, JString, required = false,
                                 default = nil)
  if valid_592788 != nil:
    section.add "X-Amz-Date", valid_592788
  var valid_592789 = header.getOrDefault("X-Amz-Credential")
  valid_592789 = validateParameter(valid_592789, JString, required = false,
                                 default = nil)
  if valid_592789 != nil:
    section.add "X-Amz-Credential", valid_592789
  var valid_592790 = header.getOrDefault("X-Amz-Security-Token")
  valid_592790 = validateParameter(valid_592790, JString, required = false,
                                 default = nil)
  if valid_592790 != nil:
    section.add "X-Amz-Security-Token", valid_592790
  var valid_592791 = header.getOrDefault("X-Amz-Algorithm")
  valid_592791 = validateParameter(valid_592791, JString, required = false,
                                 default = nil)
  if valid_592791 != nil:
    section.add "X-Amz-Algorithm", valid_592791
  var valid_592792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592792 = validateParameter(valid_592792, JString, required = false,
                                 default = nil)
  if valid_592792 != nil:
    section.add "X-Amz-SignedHeaders", valid_592792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592794: Call_UpdateMLTransform_592782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_592794.validator(path, query, header, formData, body)
  let scheme = call_592794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592794.url(scheme.get, call_592794.host, call_592794.base,
                         call_592794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592794, url, valid)

proc call*(call_592795: Call_UpdateMLTransform_592782; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_592796 = newJObject()
  if body != nil:
    body_592796 = body
  result = call_592795.call(nil, nil, nil, nil, body_592796)

var updateMLTransform* = Call_UpdateMLTransform_592782(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_592783, base: "/",
    url: url_UpdateMLTransform_592784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_592797 = ref object of OpenApiRestCall_590364
proc url_UpdatePartition_592799(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePartition_592798(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates a partition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592800 = header.getOrDefault("X-Amz-Target")
  valid_592800 = validateParameter(valid_592800, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_592800 != nil:
    section.add "X-Amz-Target", valid_592800
  var valid_592801 = header.getOrDefault("X-Amz-Signature")
  valid_592801 = validateParameter(valid_592801, JString, required = false,
                                 default = nil)
  if valid_592801 != nil:
    section.add "X-Amz-Signature", valid_592801
  var valid_592802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592802 = validateParameter(valid_592802, JString, required = false,
                                 default = nil)
  if valid_592802 != nil:
    section.add "X-Amz-Content-Sha256", valid_592802
  var valid_592803 = header.getOrDefault("X-Amz-Date")
  valid_592803 = validateParameter(valid_592803, JString, required = false,
                                 default = nil)
  if valid_592803 != nil:
    section.add "X-Amz-Date", valid_592803
  var valid_592804 = header.getOrDefault("X-Amz-Credential")
  valid_592804 = validateParameter(valid_592804, JString, required = false,
                                 default = nil)
  if valid_592804 != nil:
    section.add "X-Amz-Credential", valid_592804
  var valid_592805 = header.getOrDefault("X-Amz-Security-Token")
  valid_592805 = validateParameter(valid_592805, JString, required = false,
                                 default = nil)
  if valid_592805 != nil:
    section.add "X-Amz-Security-Token", valid_592805
  var valid_592806 = header.getOrDefault("X-Amz-Algorithm")
  valid_592806 = validateParameter(valid_592806, JString, required = false,
                                 default = nil)
  if valid_592806 != nil:
    section.add "X-Amz-Algorithm", valid_592806
  var valid_592807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592807 = validateParameter(valid_592807, JString, required = false,
                                 default = nil)
  if valid_592807 != nil:
    section.add "X-Amz-SignedHeaders", valid_592807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592809: Call_UpdatePartition_592797; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_592809.validator(path, query, header, formData, body)
  let scheme = call_592809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592809.url(scheme.get, call_592809.host, call_592809.base,
                         call_592809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592809, url, valid)

proc call*(call_592810: Call_UpdatePartition_592797; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_592811 = newJObject()
  if body != nil:
    body_592811 = body
  result = call_592810.call(nil, nil, nil, nil, body_592811)

var updatePartition* = Call_UpdatePartition_592797(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_592798, base: "/", url: url_UpdatePartition_592799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_592812 = ref object of OpenApiRestCall_590364
proc url_UpdateTable_592814(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTable_592813(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a metadata table in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592815 = header.getOrDefault("X-Amz-Target")
  valid_592815 = validateParameter(valid_592815, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTable"))
  if valid_592815 != nil:
    section.add "X-Amz-Target", valid_592815
  var valid_592816 = header.getOrDefault("X-Amz-Signature")
  valid_592816 = validateParameter(valid_592816, JString, required = false,
                                 default = nil)
  if valid_592816 != nil:
    section.add "X-Amz-Signature", valid_592816
  var valid_592817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Content-Sha256", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Date")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Date", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Credential")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Credential", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Security-Token")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Security-Token", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Algorithm")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Algorithm", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-SignedHeaders", valid_592822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592824: Call_UpdateTable_592812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_592824.validator(path, query, header, formData, body)
  let scheme = call_592824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592824.url(scheme.get, call_592824.host, call_592824.base,
                         call_592824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592824, url, valid)

proc call*(call_592825: Call_UpdateTable_592812; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_592826 = newJObject()
  if body != nil:
    body_592826 = body
  result = call_592825.call(nil, nil, nil, nil, body_592826)

var updateTable* = Call_UpdateTable_592812(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateTable",
                                        validator: validate_UpdateTable_592813,
                                        base: "/", url: url_UpdateTable_592814,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_592827 = ref object of OpenApiRestCall_590364
proc url_UpdateTrigger_592829(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTrigger_592828(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a trigger definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592830 = header.getOrDefault("X-Amz-Target")
  valid_592830 = validateParameter(valid_592830, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTrigger"))
  if valid_592830 != nil:
    section.add "X-Amz-Target", valid_592830
  var valid_592831 = header.getOrDefault("X-Amz-Signature")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = nil)
  if valid_592831 != nil:
    section.add "X-Amz-Signature", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Content-Sha256", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Date")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Date", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Credential")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Credential", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Security-Token")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Security-Token", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Algorithm")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Algorithm", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-SignedHeaders", valid_592837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592839: Call_UpdateTrigger_592827; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_592839.validator(path, query, header, formData, body)
  let scheme = call_592839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592839.url(scheme.get, call_592839.host, call_592839.base,
                         call_592839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592839, url, valid)

proc call*(call_592840: Call_UpdateTrigger_592827; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_592841 = newJObject()
  if body != nil:
    body_592841 = body
  result = call_592840.call(nil, nil, nil, nil, body_592841)

var updateTrigger* = Call_UpdateTrigger_592827(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_592828, base: "/", url: url_UpdateTrigger_592829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_592842 = ref object of OpenApiRestCall_590364
proc url_UpdateUserDefinedFunction_592844(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateUserDefinedFunction_592843(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592845 = header.getOrDefault("X-Amz-Target")
  valid_592845 = validateParameter(valid_592845, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_592845 != nil:
    section.add "X-Amz-Target", valid_592845
  var valid_592846 = header.getOrDefault("X-Amz-Signature")
  valid_592846 = validateParameter(valid_592846, JString, required = false,
                                 default = nil)
  if valid_592846 != nil:
    section.add "X-Amz-Signature", valid_592846
  var valid_592847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592847 = validateParameter(valid_592847, JString, required = false,
                                 default = nil)
  if valid_592847 != nil:
    section.add "X-Amz-Content-Sha256", valid_592847
  var valid_592848 = header.getOrDefault("X-Amz-Date")
  valid_592848 = validateParameter(valid_592848, JString, required = false,
                                 default = nil)
  if valid_592848 != nil:
    section.add "X-Amz-Date", valid_592848
  var valid_592849 = header.getOrDefault("X-Amz-Credential")
  valid_592849 = validateParameter(valid_592849, JString, required = false,
                                 default = nil)
  if valid_592849 != nil:
    section.add "X-Amz-Credential", valid_592849
  var valid_592850 = header.getOrDefault("X-Amz-Security-Token")
  valid_592850 = validateParameter(valid_592850, JString, required = false,
                                 default = nil)
  if valid_592850 != nil:
    section.add "X-Amz-Security-Token", valid_592850
  var valid_592851 = header.getOrDefault("X-Amz-Algorithm")
  valid_592851 = validateParameter(valid_592851, JString, required = false,
                                 default = nil)
  if valid_592851 != nil:
    section.add "X-Amz-Algorithm", valid_592851
  var valid_592852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592852 = validateParameter(valid_592852, JString, required = false,
                                 default = nil)
  if valid_592852 != nil:
    section.add "X-Amz-SignedHeaders", valid_592852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592854: Call_UpdateUserDefinedFunction_592842; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_592854.validator(path, query, header, formData, body)
  let scheme = call_592854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592854.url(scheme.get, call_592854.host, call_592854.base,
                         call_592854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592854, url, valid)

proc call*(call_592855: Call_UpdateUserDefinedFunction_592842; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_592856 = newJObject()
  if body != nil:
    body_592856 = body
  result = call_592855.call(nil, nil, nil, nil, body_592856)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_592842(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_592843, base: "/",
    url: url_UpdateUserDefinedFunction_592844,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_592857 = ref object of OpenApiRestCall_590364
proc url_UpdateWorkflow_592859(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWorkflow_592858(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592860 = header.getOrDefault("X-Amz-Target")
  valid_592860 = validateParameter(valid_592860, JString, required = true,
                                 default = newJString("AWSGlue.UpdateWorkflow"))
  if valid_592860 != nil:
    section.add "X-Amz-Target", valid_592860
  var valid_592861 = header.getOrDefault("X-Amz-Signature")
  valid_592861 = validateParameter(valid_592861, JString, required = false,
                                 default = nil)
  if valid_592861 != nil:
    section.add "X-Amz-Signature", valid_592861
  var valid_592862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592862 = validateParameter(valid_592862, JString, required = false,
                                 default = nil)
  if valid_592862 != nil:
    section.add "X-Amz-Content-Sha256", valid_592862
  var valid_592863 = header.getOrDefault("X-Amz-Date")
  valid_592863 = validateParameter(valid_592863, JString, required = false,
                                 default = nil)
  if valid_592863 != nil:
    section.add "X-Amz-Date", valid_592863
  var valid_592864 = header.getOrDefault("X-Amz-Credential")
  valid_592864 = validateParameter(valid_592864, JString, required = false,
                                 default = nil)
  if valid_592864 != nil:
    section.add "X-Amz-Credential", valid_592864
  var valid_592865 = header.getOrDefault("X-Amz-Security-Token")
  valid_592865 = validateParameter(valid_592865, JString, required = false,
                                 default = nil)
  if valid_592865 != nil:
    section.add "X-Amz-Security-Token", valid_592865
  var valid_592866 = header.getOrDefault("X-Amz-Algorithm")
  valid_592866 = validateParameter(valid_592866, JString, required = false,
                                 default = nil)
  if valid_592866 != nil:
    section.add "X-Amz-Algorithm", valid_592866
  var valid_592867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592867 = validateParameter(valid_592867, JString, required = false,
                                 default = nil)
  if valid_592867 != nil:
    section.add "X-Amz-SignedHeaders", valid_592867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592869: Call_UpdateWorkflow_592857; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_592869.validator(path, query, header, formData, body)
  let scheme = call_592869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592869.url(scheme.get, call_592869.host, call_592869.base,
                         call_592869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592869, url, valid)

proc call*(call_592870: Call_UpdateWorkflow_592857; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_592871 = newJObject()
  if body != nil:
    body_592871 = body
  result = call_592870.call(nil, nil, nil, nil, body_592871)

var updateWorkflow* = Call_UpdateWorkflow_592857(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_592858, base: "/", url: url_UpdateWorkflow_592859,
    schemes: {Scheme.Https, Scheme.Http})
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
