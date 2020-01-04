
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elastic Block Store
## version: 2019-11-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>You can use the Amazon Elastic Block Store (EBS) direct APIs to directly read the data on your EBS snapshots, and identify the difference between two snapshots. You can view the details of blocks in an EBS snapshot, compare the block difference between two snapshots, and directly access the data in a snapshot. If you’re an independent software vendor (ISV) who offers backup services for EBS, the EBS direct APIs makes it easier and more cost-effective to track incremental changes on your EBS volumes via EBS snapshots. This can be done without having to create new volumes from EBS snapshots, and then use EC2 instances to compare the differences.</p> <p>This API reference provides detailed information about the actions, data types, parameters, and errors of the EBS direct APIs. For more information about the elements that make up the EBS direct APIs, and examples of how to use them effectively, see <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-accessing-snapshot.html">Accessing the Contents of an EBS Snapshot</a>. For more information about how to use the EBS direct APIs, see the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-accessing-snapshots.html">EBS direct APIs User Guide</a>. To view the currently supported AWS Regions and endpoints for the EBS direct APIs, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#ebs_region">AWS Service Endpoints</a> in the <i>AWS General Reference</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ebs/
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

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ebs.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ebs.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ebs.us-west-2.amazonaws.com",
                           "eu-west-2": "ebs.eu-west-2.amazonaws.com", "ap-northeast-3": "ebs.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ebs.eu-central-1.amazonaws.com",
                           "us-east-2": "ebs.us-east-2.amazonaws.com",
                           "us-east-1": "ebs.us-east-1.amazonaws.com", "cn-northwest-1": "ebs.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ebs.ap-south-1.amazonaws.com",
                           "eu-north-1": "ebs.eu-north-1.amazonaws.com", "ap-northeast-2": "ebs.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ebs.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ebs.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ebs.eu-west-3.amazonaws.com",
                           "cn-north-1": "ebs.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ebs.sa-east-1.amazonaws.com",
                           "eu-west-1": "ebs.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ebs.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ebs.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ebs.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ebs.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ebs.ap-southeast-1.amazonaws.com",
      "us-west-2": "ebs.us-west-2.amazonaws.com",
      "eu-west-2": "ebs.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ebs.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ebs.eu-central-1.amazonaws.com",
      "us-east-2": "ebs.us-east-2.amazonaws.com",
      "us-east-1": "ebs.us-east-1.amazonaws.com",
      "cn-northwest-1": "ebs.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ebs.ap-south-1.amazonaws.com",
      "eu-north-1": "ebs.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ebs.ap-northeast-2.amazonaws.com",
      "us-west-1": "ebs.us-west-1.amazonaws.com",
      "us-gov-east-1": "ebs.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ebs.eu-west-3.amazonaws.com",
      "cn-north-1": "ebs.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ebs.sa-east-1.amazonaws.com",
      "eu-west-1": "ebs.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ebs.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ebs.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ebs.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ebs"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetSnapshotBlock_601718 = ref object of OpenApiRestCall_601380
proc url_GetSnapshotBlock_601720(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "snapshotId" in path, "`snapshotId` is a required path parameter"
  assert "blockIndex" in path, "`blockIndex` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/snapshots/"),
               (kind: VariableSegment, value: "snapshotId"),
               (kind: ConstantSegment, value: "/blocks/"),
               (kind: VariableSegment, value: "blockIndex"),
               (kind: ConstantSegment, value: "#blockToken")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSnapshotBlock_601719(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   snapshotId: JString (required)
  ##             : The ID of the snapshot containing the block from which to get data.
  ##   blockIndex: JInt (required)
  ##             : <p>The block index of the block from which to get data.</p> <p>Obtain the <code>block index</code> by running the <code>list changed blocks</code> or <code>list snapshot blocks</code> operations.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `snapshotId` field"
  var valid_601846 = path.getOrDefault("snapshotId")
  valid_601846 = validateParameter(valid_601846, JString, required = true,
                                 default = nil)
  if valid_601846 != nil:
    section.add "snapshotId", valid_601846
  var valid_601847 = path.getOrDefault("blockIndex")
  valid_601847 = validateParameter(valid_601847, JInt, required = true, default = nil)
  if valid_601847 != nil:
    section.add "blockIndex", valid_601847
  result.add "path", section
  ## parameters in `query` object:
  ##   blockToken: JString (required)
  ##             : <p>The block token of the block from which to get data.</p> <p>Obtain the <code>block token</code> by running the <code>list changed blocks</code> or <code>list snapshot blocks</code> operations.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `blockToken` field"
  var valid_601848 = query.getOrDefault("blockToken")
  valid_601848 = validateParameter(valid_601848, JString, required = true,
                                 default = nil)
  if valid_601848 != nil:
    section.add "blockToken", valid_601848
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
  var valid_601849 = header.getOrDefault("X-Amz-Signature")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Signature", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Content-Sha256", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Date")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Date", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-Credential")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-Credential", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-Security-Token")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-Security-Token", valid_601853
  var valid_601854 = header.getOrDefault("X-Amz-Algorithm")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "X-Amz-Algorithm", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-SignedHeaders", valid_601855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601878: Call_GetSnapshotBlock_601718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ## 
  let valid = call_601878.validator(path, query, header, formData, body)
  let scheme = call_601878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601878.url(scheme.get, call_601878.host, call_601878.base,
                         call_601878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601878, url, valid)

proc call*(call_601949: Call_GetSnapshotBlock_601718; snapshotId: string;
          blockIndex: int; blockToken: string): Recallable =
  ## getSnapshotBlock
  ## Returns the data in a block in an Amazon Elastic Block Store snapshot.
  ##   snapshotId: string (required)
  ##             : The ID of the snapshot containing the block from which to get data.
  ##   blockIndex: int (required)
  ##             : <p>The block index of the block from which to get data.</p> <p>Obtain the <code>block index</code> by running the <code>list changed blocks</code> or <code>list snapshot blocks</code> operations.</p>
  ##   blockToken: string (required)
  ##             : <p>The block token of the block from which to get data.</p> <p>Obtain the <code>block token</code> by running the <code>list changed blocks</code> or <code>list snapshot blocks</code> operations.</p>
  var path_601950 = newJObject()
  var query_601952 = newJObject()
  add(path_601950, "snapshotId", newJString(snapshotId))
  add(path_601950, "blockIndex", newJInt(blockIndex))
  add(query_601952, "blockToken", newJString(blockToken))
  result = call_601949.call(path_601950, query_601952, nil, nil, nil)

var getSnapshotBlock* = Call_GetSnapshotBlock_601718(name: "getSnapshotBlock",
    meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{snapshotId}/blocks/{blockIndex}#blockToken",
    validator: validate_GetSnapshotBlock_601719, base: "/",
    url: url_GetSnapshotBlock_601720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangedBlocks_601991 = ref object of OpenApiRestCall_601380
proc url_ListChangedBlocks_601993(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "secondSnapshotId" in path,
        "`secondSnapshotId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/snapshots/"),
               (kind: VariableSegment, value: "secondSnapshotId"),
               (kind: ConstantSegment, value: "/changedblocks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListChangedBlocks_601992(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   secondSnapshotId: JString (required)
  ##                   : The ID of the second snapshot to use for the comparison.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `secondSnapshotId` field"
  var valid_601994 = path.getOrDefault("secondSnapshotId")
  valid_601994 = validateParameter(valid_601994, JString, required = true,
                                 default = nil)
  if valid_601994 != nil:
    section.add "secondSnapshotId", valid_601994
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   pageToken: JString
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: JInt
  ##                     : <p>The block index from which the comparison should start.</p> <p>The list in the response will start from this block index or the next valid block index in the snapshots.</p>
  ##   firstSnapshotId: JString
  ##                  : The ID of the first snapshot to use for the comparison.
  ##   maxResults: JInt
  ##             : The number of results to return.
  section = newJObject()
  var valid_601995 = query.getOrDefault("MaxResults")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "MaxResults", valid_601995
  var valid_601996 = query.getOrDefault("NextToken")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "NextToken", valid_601996
  var valid_601997 = query.getOrDefault("pageToken")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "pageToken", valid_601997
  var valid_601998 = query.getOrDefault("startingBlockIndex")
  valid_601998 = validateParameter(valid_601998, JInt, required = false, default = nil)
  if valid_601998 != nil:
    section.add "startingBlockIndex", valid_601998
  var valid_601999 = query.getOrDefault("firstSnapshotId")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "firstSnapshotId", valid_601999
  var valid_602000 = query.getOrDefault("maxResults")
  valid_602000 = validateParameter(valid_602000, JInt, required = false, default = nil)
  if valid_602000 != nil:
    section.add "maxResults", valid_602000
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
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_ListChangedBlocks_601991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_ListChangedBlocks_601991; secondSnapshotId: string;
          MaxResults: string = ""; NextToken: string = ""; pageToken: string = "";
          startingBlockIndex: int = 0; firstSnapshotId: string = ""; maxResults: int = 0): Recallable =
  ## listChangedBlocks
  ## Returns the block indexes and block tokens for blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   secondSnapshotId: string (required)
  ##                   : The ID of the second snapshot to use for the comparison.
  ##   pageToken: string
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: int
  ##                     : <p>The block index from which the comparison should start.</p> <p>The list in the response will start from this block index or the next valid block index in the snapshots.</p>
  ##   firstSnapshotId: string
  ##                  : The ID of the first snapshot to use for the comparison.
  ##   maxResults: int
  ##             : The number of results to return.
  var path_602010 = newJObject()
  var query_602011 = newJObject()
  add(query_602011, "MaxResults", newJString(MaxResults))
  add(query_602011, "NextToken", newJString(NextToken))
  add(path_602010, "secondSnapshotId", newJString(secondSnapshotId))
  add(query_602011, "pageToken", newJString(pageToken))
  add(query_602011, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_602011, "firstSnapshotId", newJString(firstSnapshotId))
  add(query_602011, "maxResults", newJInt(maxResults))
  result = call_602009.call(path_602010, query_602011, nil, nil, nil)

var listChangedBlocks* = Call_ListChangedBlocks_601991(name: "listChangedBlocks",
    meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{secondSnapshotId}/changedblocks",
    validator: validate_ListChangedBlocks_601992, base: "/",
    url: url_ListChangedBlocks_601993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSnapshotBlocks_602012 = ref object of OpenApiRestCall_601380
proc url_ListSnapshotBlocks_602014(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "snapshotId" in path, "`snapshotId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/snapshots/"),
               (kind: VariableSegment, value: "snapshotId"),
               (kind: ConstantSegment, value: "/blocks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSnapshotBlocks_602013(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   snapshotId: JString (required)
  ##             : The ID of the snapshot from which to get block indexes and block tokens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `snapshotId` field"
  var valid_602015 = path.getOrDefault("snapshotId")
  valid_602015 = validateParameter(valid_602015, JString, required = true,
                                 default = nil)
  if valid_602015 != nil:
    section.add "snapshotId", valid_602015
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   pageToken: JString
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: JInt
  ##                     : The block index from which the list should start. The list in the response will start from this block index or the next valid block index in the snapshot.
  ##   maxResults: JInt
  ##             : The number of results to return.
  section = newJObject()
  var valid_602016 = query.getOrDefault("MaxResults")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "MaxResults", valid_602016
  var valid_602017 = query.getOrDefault("NextToken")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "NextToken", valid_602017
  var valid_602018 = query.getOrDefault("pageToken")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "pageToken", valid_602018
  var valid_602019 = query.getOrDefault("startingBlockIndex")
  valid_602019 = validateParameter(valid_602019, JInt, required = false, default = nil)
  if valid_602019 != nil:
    section.add "startingBlockIndex", valid_602019
  var valid_602020 = query.getOrDefault("maxResults")
  valid_602020 = validateParameter(valid_602020, JInt, required = false, default = nil)
  if valid_602020 != nil:
    section.add "maxResults", valid_602020
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
  var valid_602021 = header.getOrDefault("X-Amz-Signature")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Signature", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Content-Sha256", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Date")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Date", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Credential")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Credential", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Security-Token")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Security-Token", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Algorithm")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Algorithm", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-SignedHeaders", valid_602027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602028: Call_ListSnapshotBlocks_602012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ## 
  let valid = call_602028.validator(path, query, header, formData, body)
  let scheme = call_602028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602028.url(scheme.get, call_602028.host, call_602028.base,
                         call_602028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602028, url, valid)

proc call*(call_602029: Call_ListSnapshotBlocks_602012; snapshotId: string;
          MaxResults: string = ""; NextToken: string = ""; pageToken: string = "";
          startingBlockIndex: int = 0; maxResults: int = 0): Recallable =
  ## listSnapshotBlocks
  ## Returns the block indexes and block tokens for blocks in an Amazon Elastic Block Store snapshot.
  ##   snapshotId: string (required)
  ##             : The ID of the snapshot from which to get block indexes and block tokens.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   pageToken: string
  ##            : The token to request the next page of results.
  ##   startingBlockIndex: int
  ##                     : The block index from which the list should start. The list in the response will start from this block index or the next valid block index in the snapshot.
  ##   maxResults: int
  ##             : The number of results to return.
  var path_602030 = newJObject()
  var query_602031 = newJObject()
  add(path_602030, "snapshotId", newJString(snapshotId))
  add(query_602031, "MaxResults", newJString(MaxResults))
  add(query_602031, "NextToken", newJString(NextToken))
  add(query_602031, "pageToken", newJString(pageToken))
  add(query_602031, "startingBlockIndex", newJInt(startingBlockIndex))
  add(query_602031, "maxResults", newJInt(maxResults))
  result = call_602029.call(path_602030, query_602031, nil, nil, nil)

var listSnapshotBlocks* = Call_ListSnapshotBlocks_602012(
    name: "listSnapshotBlocks", meth: HttpMethod.HttpGet, host: "ebs.amazonaws.com",
    route: "/snapshots/{snapshotId}/blocks",
    validator: validate_ListSnapshotBlocks_602013, base: "/",
    url: url_ListSnapshotBlocks_602014, schemes: {Scheme.Https, Scheme.Http})
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
